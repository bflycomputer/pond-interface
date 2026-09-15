pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.VectorImage

Item {
    id: root
    required property var theme
    property bool restartEnabled: false
    property bool expanded: false
    readonly property bool restartShown: expanded && restartEnabled && enabled
    signal shutdownRequested
    signal restartRequested

    width: 80
    height: restartShown ? 160 : 80
    onEnabledChanged: { if (!enabled) expanded = false; }
    onRestartEnabledChanged: { if (!restartEnabled) expanded = false; }

    // A single hover region joins both rows, without an exit/enter gap.
    HoverHandler {
        onHoveredChanged: { if (!hovered) root.expanded = false; }
    }

    component ActionButton: Item {
        id: action
        required property string label
        required property string iconName
        readonly property bool hovered: mouse.containsMouse && enabled
        signal clicked
        width: 80
        height: 80

        VectorImage {
            objectName: action.objectName + "Icon"
            anchors.fill: parent
            source: Qt.resolvedUrl("assets/" + action.iconName + (action.hovered ? "-hover" : "") + ".svg")
            preferredRendererType: VectorImage.CurveRenderer
        }
        Text {
            renderType: Text.CurveRendering
            objectName: action.objectName + "Label"
            x: -10 - width
            y: 26
            height: 28
            text: action.label
            font.family: root.theme.displayFont
            font.styleName: "Book"
            font.pixelSize: 20
            lineHeightMode: Text.FixedHeight
            lineHeight: 28
            color: root.theme.powerLabel
            opacity: action.hovered ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 120 } }
        }
        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: action.clicked()
        }
    }

    ActionButton {
        objectName: "shutdownButton"
        label: "Shut down"
        iconName: "power"
        onHoveredChanged: { if (hovered && root.restartEnabled) root.expanded = true; }
        onClicked: root.shutdownRequested()
    }
    ActionButton {
        objectName: "restartButton"
        y: 80
        label: "Restart"
        iconName: "restart"
        enabled: root.restartShown
        opacity: root.restartShown ? 1 : 0
        visible: root.restartShown || opacity > 0
        Behavior on opacity { NumberAnimation { duration: 120 } }
        onClicked: root.restartRequested()
    }
}
