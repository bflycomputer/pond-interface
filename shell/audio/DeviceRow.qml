import QtQuick
import "." as Audio
import ".."

Item {
  id: root

  property var device
  property bool selected: false
  property bool interactive: true
  signal clicked

  implicitWidth: PanelStyle.rowWidth
  implicitHeight: PanelStyle.audioRowHeight

  Rectangle {
    anchors.fill: parent
    radius: PanelStyle.rowRadius
    color: pointer.containsMouse ? PanelStyle.hover
        : Qt.rgba(38 / 255, 38 / 255, 38 / 255, 0)

    Behavior on color {
      ColorAnimation {
        duration: PanelStyle.controlDuration
        easing.type: Easing.OutCubic
      }
    }
  }

  Text {
    x: 12
    width: 244
    anchors.verticalCenter: parent.verticalCenter
    text: Audio.State.displayName(root.device)
    color: "white"
    elide: Text.ElideRight
    font.family: Theme.fontFamily
    font.weight: Font.Medium
    font.pixelSize: 13
  }

  Rectangle {
    x: 272
    y: 12
    width: 16
    height: 16
    radius: 8
    color: root.selected ? "white" : "transparent"
    border.width: root.selected ? 0 : 1
    border.color: "white"
    opacity: root.selected ? 1 : 0.3

    Image {
      anchors.centerIn: parent
      width: 12
      height: 12
      visible: root.selected
      source: Qt.resolvedUrl("../assets/check.svg")
      sourceSize: Qt.size(24, 24)
    }
  }

  MouseArea {
    id: pointer
    anchors.fill: parent
    enabled: root.interactive
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: root.clicked()
  }
}
