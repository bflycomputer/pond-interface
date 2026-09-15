pragma ComponentBehavior: Bound
import QtQuick
import "GridState.js" as GridState
import "RevealLayout.js" as Layout

Item {
    id: root
    required property var controller
    property int exitStep: 0
    required property var theme
    property string visibilityPhase: "shown"
    property real elapsedMs: 0
    property var fadeRanks: Layout.ranks(21)
    readonly property int visibleCellCount: controller.visibleCellCount
    property bool ready: false
    Component.onCompleted: ready = true
    readonly property var edges: Layout.edges(GridState.CELL_POSITIONS)
    width: 400; height: 400
    function cellOpacity(cellIndex) {
        const item = cells.itemAt(cellIndex);
        return item ? item.opacity : 0;
    }
    function edgeOpacity(owners) {
        let result = 0;
        for (const cellIndex of owners) result = Math.max(result, cellOpacity(cellIndex));
        return result;
    }
    function edgeColor(owners) {
        let priority = 0;
        let color = theme.grid;
        for (const cellIndex of owners) {
            if (cellOpacity(cellIndex) <= 0) continue;
            const mode = controller.cellVisual(cellIndex, exitStep).mode;
            const rank = mode === "successFill" || mode === "successOutline" ? 3
                : mode === "errorOutline" ? 2 : mode === "errorFill" ? 1 : 0;
            if (rank > priority) {
                priority = rank;
                color = rank === 3 ? theme.success : rank === 2 ? theme.lavender : theme.error;
            }
        }
        return color;
    }
    Repeater {
        id: cells
        model: 21
        delegate: Item {
            id: slot
            required property int index
            objectName: "radialCell" + index
            property bool available: index < root.visibleCellCount
            property real appearOpacity: index < 13 ? 1 : 0
            property int appearDelayMs: 0
            readonly property var visual: root.controller.cellVisual(index, root.exitStep)
            readonly property bool appearDot: index >= 13 && appearAnimation.running
                && root.controller.animationState.inputLength <= index
            x: GridState.CELL_POSITIONS[index][0]; y: GridState.CELL_POSITIONS[index][1]
            width: 80; height: 80
            opacity: {
                if (!available || visual.mode === "hidden") return 0;
                let alpha = appearOpacity;
                const ramp = Layout.progress(root.elapsedMs, root.fadeRanks[index] * 4, 120);
                if (root.visibilityPhase === "out") alpha *= 1 - ramp;
                else if (root.visibilityPhase === "in") alpha *= ramp;
                else if (root.visibilityPhase === "hidden") alpha = 0;
                return alpha;
            }
            function updateAppearance() {
                appearAnimation.stop();
                // Start the exit transition with all available cells fully visible.
                if (index < 13 || root.exitStep > 0) { appearOpacity = 1; return; }
                appearOpacity = 0;
                if (available) {
                    appearDelayMs = root.fadeRanks[index] * 5;
                    appearAnimation.restart();
                }
            }
            onAvailableChanged: updateAppearance()
            Component.onCompleted: updateAppearance()
            SequentialAnimation {
                id: appearAnimation
                PauseAnimation { duration: slot.appearDelayMs }
                NumberAnimation { target: slot; property: "appearOpacity"; to: 1; duration: 120 }
                PauseAnimation { duration: 230 }
            }
            Cell {
                anchors.fill: parent
                theme: root.theme
                visual: slot.appearDot ? { mode: "idleDot", shape: -1 } : slot.visual
            }
        }
    }
    Repeater {
        model: root.edges
        delegate: Rectangle {
            required property var modelData
            x: modelData.x; y: modelData.y
            width: modelData.w; height: modelData.h
            color: root.ready ? root.edgeColor(modelData.owners) : root.theme.grid
            opacity: root.ready ? root.edgeOpacity(modelData.owners) : 0
        }
    }
}
