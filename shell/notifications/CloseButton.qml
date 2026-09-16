import QtQuick
import "." as Notifications
import ".." as Shell

Rectangle {
  id: root

  signal clicked
  readonly property bool hovered: pointer.containsMouse

  implicitWidth: Notifications.Style.closeSize
  implicitHeight: Notifications.Style.closeSize
  radius: 4
  color: pointer.containsMouse
      ? Notifications.Style.closeHover : Shell.Theme.sidebarV3Control
  antialiasing: true

  Behavior on color {
    ColorAnimation {
      duration: Shell.Theme.sidebarHoverDuration
      easing.type: Easing.OutCubic
    }
  }

  Image {
    anchors.centerIn: parent
    width: Notifications.Style.closeIconSize
    height: Notifications.Style.closeIconSize
    source: Qt.resolvedUrl("../assets/close.svg")
    sourceSize: Qt.size(Notifications.Style.closeIconSize * 2,
                        Notifications.Style.closeIconSize * 2)
    fillMode: Image.PreserveAspectFit
    smooth: true
    antialiasing: true
  }

  MouseArea {
    id: pointer
    anchors.fill: parent
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton
    cursorShape: Qt.PointingHandCursor
    onClicked: root.clicked()
  }
}
