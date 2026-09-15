pragma ComponentBehavior: Bound
import QtQuick
import "RevealLayout.js" as Layout

Item {
    id: root
    required property var controller
    property int exitStep: 0
    required property var theme
    property bool showPassword: false
    property string revealText: ""
    property bool interactive: true
    property real displayScale: 1
    property int characterRevision: 0
    property string displayPhase: "radial"
    property real elapsedMs: 0
    property var fadeRanks: Layout.ranks(21)
    readonly property bool revealContentVisible: displayPhase === "revealIn" || displayPhase === "revealed" || displayPhase === "revealOut"
    readonly property bool dateTimeVisible: displayPhase === "radial" || displayPhase === "radialIn"
    readonly property int characterCount: Layout.count(revealText.length)
    readonly property var arrangement: Layout.layout(characterCount)
    readonly property real revealScale: Math.min(1, Math.max(0.1, (width - 192) / (arrangement.width + 160)))
    // The revision makes newly created/deleted delegates visible to this binding.
    function outlineBoxes(revision) {
        const boxes = [];
        for (let index = 0; index < characters.count; ++index) {
            const cell = characters.itemAt(index);
            if (cell) boxes.push({x:cell.x, y:cell.y, alpha:cell.opacity});
        }
        boxes.push({x:submitButton.x, y:submitButton.y, alpha:submitButton.opacity});
        return boxes;
    }
    signal submitRequested
    function begin(next) {
        clock.stop(); elapsedMs = 0; displayPhase = next; fadeRanks = Layout.ranks(21);
        if (next !== "radial" && next !== "revealed") clock.restart();
    }
    function reset() { begin("radial"); }
    onShowPasswordChanged: {
        if (showPassword && interactive) {
            if (displayPhase === "radial" || displayPhase === "radialIn" || displayPhase === "radialOut") begin("radialOut");
            else begin("revealIn");
        } else if (revealContentVisible) begin("revealOut");
        else if (displayPhase !== "radial") begin("radialIn");
    }
    onInteractiveChanged: if (!interactive) reset()
    NumberAnimation {
        id: clock
        target: root; property: "elapsedMs"
        from: 0
        to: root.displayPhase === "revealIn" ? Layout.REVEAL_DURATION_MS : 210
        duration: to
        onFinished: {
            if (root.displayPhase === "radialOut") root.begin(root.showPassword ? "revealIn" : "radialIn");
            else if (root.displayPhase === "revealIn") root.begin(root.showPassword ? "revealed" : "revealOut");
            else if (root.displayPhase === "revealOut") root.begin(root.showPassword ? "revealIn" : "radialIn");
            else if (root.displayPhase === "radialIn") root.begin(root.showPassword ? "radialOut" : "radial");
        }
    }
    CellGrid {
        objectName: "lockGrid"
        x: (root.width - width) / 2; y: 320
        controller: root.controller; theme: root.theme
        exitStep: root.exitStep
        visibilityPhase: root.displayPhase === "radial" ? "shown" : root.displayPhase === "radialOut" ? "out"
            : root.displayPhase === "radialIn" ? "in" : "hidden"
        elapsedMs: root.elapsedMs; fadeRanks: root.fadeRanks
    }
    Item {
        id: revealed
        objectName: "revealedFields"
        width: root.arrangement.width; height: root.arrangement.height
        x: (root.width - width * root.revealScale) / 2; y: 480
        transform: Scale { xScale: root.revealScale; yScale: root.revealScale }
        visible: root.revealContentVisible
        Behavior on x { enabled: root.displayPhase === "revealed"; NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
        Repeater {
            id: characters
            model: root.characterCount
            onItemAdded: root.characterRevision++
            onItemRemoved: root.characterRevision++
            delegate: Item {
                id: character
                required property int index
                objectName: "revealedCell" + index
                readonly property var position: root.arrangement.cells[index] || {x:0, y:0, dx:0, dy:0, wave:1}
                readonly property real movement: root.displayPhase === "revealIn"
                    ? Layout.revealMovement(root.elapsedMs, position.wave) : 1
                x: position.x + position.dx * (1 - movement)
                y: position.y + position.dy * (1 - movement)
                width: 80; height: 80
                opacity: root.displayPhase === "revealOut"
                    ? 1 - Layout.progress(root.elapsedMs, root.fadeRanks[index] * 4, 120)
                    : root.displayPhase === "revealIn" ? Layout.revealFade(root.elapsedMs, root.fadeRanks[index]) : 1
                Behavior on x { enabled: root.displayPhase === "revealed"; NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                Behavior on y { enabled: root.displayPhase === "revealed"; NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                Text {
                    objectName: "revealedText" + character.index
                    anchors.centerIn: parent
                    text: root.revealContentVisible ? root.revealText.charAt(character.index) : ""
                    color: "white"
                    font.family: root.theme.displayFont; font.styleName: "Book"; font.pixelSize: 20
                }
            }
        }
        Rectangle {
            id: submitButton
            objectName: "revealSubmitButton"
            x: root.arrangement.submitX; y: root.arrangement.submitY
            width: 80; height: 80
            color: root.theme.orange
            opacity: root.displayPhase === "revealIn" ? Layout.revealFade(root.elapsedMs, 10)
                : root.displayPhase === "revealOut" ? 1 - Layout.progress(root.elapsedMs, 40, 120) : 1
            Image {
                anchors.centerIn: parent
                width: 22; height: 22
                source: Qt.resolvedUrl("../assets/enter-glyph.svg")
            }
            MouseArea {
                anchors.fill: parent
                enabled: root.interactive && root.characterCount > 0 && root.displayPhase === "revealed"
                cursorShape: Qt.PointingHandCursor
                onClicked: root.submitRequested()
            }
        }
        RevealOutline {
            objectName: "revealOutline"
            boxes: root.outlineBoxes(root.characterRevision)
            pixelScale: root.displayScale * root.revealScale * Screen.devicePixelRatio
            originX: revealed.x * root.displayScale * Screen.devicePixelRatio
            originY: revealed.y * root.displayScale * Screen.devicePixelRatio
        }
    }
}
