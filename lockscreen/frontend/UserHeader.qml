pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.VectorImage

Item {
    id: root
    required property var theme
    property string displayName: ""
    property bool multipleUsers: false
    property var compositors: []
    property int compositorIndex: -1
    signal userStepRequested(int direction)
    signal compositorRequested(int index)
    height: 40

    Rectangle {
        id: nameplate
        objectName: "userNameplate"
        x: (root.width - width) / 2
        width: Math.min(displayNameText.implicitWidth + 30, root.width * 0.4)
        height: 40
        color: root.theme.lavender
        Text {
            renderType: Text.CurveRendering
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
        VectorImage {
            anchors.centerIn: parent
            width: 24; height: 24
            source: Qt.resolvedUrl("assets/user-chevron.svg")
            rotation: arrow.direction > 0 ? -90 : 90
            opacity: arrow.hovered ? 1 : 0.7
            preferredRendererType: VectorImage.CurveRenderer
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

    Rectangle {
        x: 44; y: 14
        width: 1; height: 16
        visible: root.compositors.length > 1
        color: root.theme.lavender
        opacity: 0.5
    }
    Item {
        id: selector
        x: 54; y: 8
        width: Math.max(110, selectedName.implicitWidth + 26, alternatives.implicitWidth)
        height: expanded ? alternatives.y + alternatives.height : 28
        visible: root.compositors.length > 1
        readonly property bool expanded: root.enabled && hover.hovered
        HoverHandler { id: hover }
        Text {
            renderType: Text.CurveRendering
            id: selectedName
            text: root.compositors[root.compositorIndex] || ""
            color: root.theme.lavender
            font.family: root.theme.displayFont
            font.styleName: "Book"
            font.pixelSize: 20
            lineHeightMode: Text.FixedHeight
            lineHeight: 28
        }
        VectorImage {
            preferredRendererType: VectorImage.CurveRenderer
            x: selectedName.implicitWidth + 2; y: 2
            width: 24; height: 24
            source: Qt.resolvedUrl("assets/compositor-chevron.svg")
        }
        Column {
            id: alternatives
            y: 32
            visible: selector.expanded
            Repeater {
                model: root.compositors
                delegate: Item {
                    id: row
                    required property string modelData
                    required property int index
                    objectName: "compositor" + index
                    visible: index !== root.compositorIndex
                    width: Math.max(110, label.implicitWidth + 26)
                    height: visible ? 32 : 0
                    Text {
                        renderType: Text.CurveRendering
                        id: label
                        text: row.modelData
                        opacity: choice.containsMouse ? 1 : 0.5
                        color: root.theme.lavender
                        font.family: root.theme.displayFont
                        font.styleName: "Book"
                        font.pixelSize: 20
                        lineHeightMode: Text.FixedHeight
                        lineHeight: 28
                    }
                    MouseArea {
                        id: choice
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.compositorRequested(row.index)
                    }
                }
            }
        }
    }
}
