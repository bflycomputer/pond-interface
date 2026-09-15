import QtQuick
import QtQuick.VectorImage

Item {
    id: root

    required property var theme
    required property var visual

    width: 80
    height: 80
    opacity: visual.mode === "hidden" ? 0 : 1

    function isShapeMode() {
        return visual.mode === "shape" || visual.mode === "delete";
    }

    function shapeSource(shape) {
        const index = Math.max(0, Math.min(3, shape));
        const names = ["flower", "hexagon", "lily", "leaf"];
        const prefix = visual.mode === "delete" && index > 0 ? "glyph" : "shape";
        return Qt.resolvedUrl("../assets/" + prefix + "-" + names[index] + ".svg");
    }

    Rectangle {
        anchors.fill: parent
        color: {
            if (root.visual.mode === "caretOn" || root.visual.mode === "caretEnter")
                return root.theme.orange;
            if (root.visual.mode === "shape")
                return root.theme.lavender;
            if (root.visual.mode === "delete" || root.visual.mode === "errorFill")
                return root.theme.error;
            if (root.visual.mode === "successFill")
                return root.theme.success;
            return "transparent";
        }
        // Shared edges are drawn once by CellGrid.
        border.width: 0
    }

    VectorImage {
        anchors.centerIn: parent
        width: root.visual.shape === 0 ? 36 : 80
        height: root.visual.shape === 0 ? 36 : 80
        source: root.shapeSource(root.visual.shape)
        fillMode: VectorImage.PreserveAspectFit
        preferredRendererType: VectorImage.CurveRenderer
        visible: root.isShapeMode()
    }

    VectorImage {
        objectName: "enterBlinker"
        anchors.centerIn: parent
        width: 27
        height: 27
        source: Qt.resolvedUrl("../assets/blinker-enter-glyph.svg")
        preferredRendererType: VectorImage.CurveRenderer
        visible: root.visual.mode === "caretEnter"
    }

    Rectangle {
        width: 10
        height: 10
        radius: 5
        anchors.centerIn: parent
        color: root.visual.mode === "caretOn" ? root.theme.orangeDot : root.theme.lavender
        visible: root.visual.mode === "idleDot" || root.visual.mode === "caretOn" || root.visual.mode === "caretOff"
    }

    Behavior on opacity { NumberAnimation { duration: 45 } }
}
