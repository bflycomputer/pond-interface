import QtQuick
import ".." as Shell

Item {
  id: root
  property bool revealed: false
  signal activated

  visible: opacity > 0
  opacity: revealed ? 1 : 0
  scale: revealed ? 1 : 0.65
  Behavior on opacity { Shell.HoverAnimation {} }
  Behavior on scale { Shell.HoverAnimation {} }

  Rectangle {
    anchors.fill: parent
    radius: width / 2
    antialiasing: true
    color: pointer.containsMouse ? Shell.Theme.workspaceControlHover : "transparent"
    border.width: pointer.containsMouse ? 0 : Shell.Theme.sidebarStrokeWidth
    border.color: Shell.Theme.workspaceIconOutline
    Behavior on color {
      ColorAnimation { duration: Shell.Theme.sidebarHoverDuration; easing.type: Easing.OutCubic }
    }
  }
  Image {
    anchors.centerIn: parent
    width: Shell.Theme.workspaceIconSize
    height: width
    source: "../assets/navigation/plus.svg"
    sourceSize: Qt.size(width * 2, height * 2)
  }
  MouseArea {
    id: pointer
    anchors.fill: parent
    enabled: root.revealed
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    Accessible.role: Accessible.Button
    Accessible.name: "Open launcher on this workspace"
    Accessible.onPressAction: root.activated()
    onClicked: root.activated()
  }
}
