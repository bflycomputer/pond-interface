pragma ComponentBehavior: Bound
import QtQuick

Item {
    id: root
    required property var theme
    property string displayName: ""
    property bool multipleUsers: false
    property var compositors: []
    property string selectedCompositor: ""
    signal userStepRequested(int direction)
    signal compositorRequested(string name)
    height: Math.max(40, 8 + compositors.length * 30)

    Rectangle {
        id: nameplate
        objectName: "userNameplate"
        x: (root.width - width) / 2
        width: Math.min(displayNameText.implicitWidth + 30, root.width * 0.4)
        height: 40
        color: root.theme.lavender
        Text {
            id: displayNameText
            objectName: "displayNameLabel"
            anchors.centerIn: parent
            width: parent.width - 30
            text: root.displayName
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignHCenter
            color: root.theme.glyph
            font.family: root.theme.displayFont
            font.styleName: "Book"
            font.pixelSize: 20
        }
    }

    component UserArrow: Rectangle {
        id: arrow
        required property int direction
        readonly property bool hovered: mouse.containsMouse && enabled
        width: 40; height: 40
        visible: root.multipleUsers
        color: hovered ? Qt.rgba(root.theme.lavender.r, root.theme.lavender.g, root.theme.lavender.b, 0.2) : "transparent"
        Image {
            anchors.centerIn: parent
            width: 24; height: 24
            source: Qt.resolvedUrl("assets/user-chevron.svg")
            rotation: arrow.direction > 0 ? -90 : 90
            opacity: arrow.hovered ? 1 : 0.7
            asynchronous: false
        }
        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.userStepRequested(arrow.direction)
        }
    }
    UserArrow {
        objectName: "previousUser"
        x: nameplate.x - width
        direction: -1
    }
    UserArrow {
        objectName: "nextUser"
        x: nameplate.x + nameplate.width
        direction: 1
    }

    Column {
        x: 8; y: 8
        Repeater {
            model: root.compositors
            delegate: Item {
                id: row
                required property string modelData
                required property int index
                readonly property bool selected: modelData === root.selectedCompositor
                objectName: "compositor" + index
                width: Math.max(120, label.implicitWidth + 24)
                height: 30
                opacity: selected ? 1 : mouse.containsMouse && enabled ? 0.8 : 0.5
                Rectangle {
                    x: 4; y: 11
                    width: 6; height: 6; radius: 3
                    color: row.selected ? root.theme.lavender : "transparent"
                    border.color: root.theme.lavender
                    border.width: 1
                }
                Text {
                    id: label
                    x: 16
                    text: row.modelData
                    color: root.theme.lavender
                    font.family: root.theme.displayFont
                    font.styleName: "Book"
                    font.pixelSize: 20
                    lineHeightMode: Text.FixedHeight
                    lineHeight: 28
                }
                MouseArea {
                    id: mouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.compositorRequested(row.modelData)
                }
            }
        }
    }
}
