pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Wayland
import "." as Battery
import ".." as Shell

PanelWindow {
  id: root
  required property var bar

  screen: bar.screen
  visible: bar.popup === "battery"
  color: "transparent"
  BackgroundEffect.blurRegion: Shell.Theme.translucent ? card.blurRegion : null
  anchors { left: true; right: true; top: true; bottom: true }
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.namespace: "pond-battery-" + (screen ? screen.name : "unknown")
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
  WlrLayershell.exclusionMode: ExclusionMode.Ignore

  mask: Region {
    intersection: Intersection.Subtract
    regions: [root.bar.mask]
  }

  onVisibleChanged: if (visible) card.forceActiveFocus();

  MouseArea {
    anchors.fill: parent
    acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
    onClicked: root.bar.popup = ""
  }

  Battery.Card {
    id: card
    x: Shell.Theme.sidebarOuterMargin + root.bar.cardWidth + 10
    y: Shell.Theme.sidebarOuterMargin
    Keys.onEscapePressed: root.bar.popup = ""
  }
}
