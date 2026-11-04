pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Wayland
import "." as Calendar
import ".." as Shell

PanelWindow {
  id: root
  required property var bar
  readonly property real panelLeft: Shell.Theme.sidebarOuterMargin + bar.cardWidth + 10
  readonly property real panelTop: Shell.Theme.sidebarOuterMargin

  screen: bar.screen
  visible: bar.popup === "calendar"
  color: "transparent"
  BackgroundEffect.blurRegion: Shell.Theme.translucent ? calendar.blurRegion : null
  anchors { left: true; right: true; top: true; bottom: true }
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.namespace: "pond-calendar-" + (screen ? screen.name : "unknown")
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
  WlrLayershell.exclusionMode: ExclusionMode.Ignore

  mask: Region {
    intersection: Intersection.Subtract
    regions: [root.bar.mask]
  }

  onVisibleChanged: {
    if (visible) {
      calendar.goToday();
      calendar.forceActiveFocus();
    }
  }

  MouseArea {
    anchors.fill: parent
    acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
    onClicked: root.bar.popup = ""
  }

  Shell.Shadow {
    anchors.fill: calendar
    cornerRadius: calendar.radius
    shadows: Shell.PanelStyle.frontShadows
  }

  Calendar.Card {
    id: calendar
    x: root.panelLeft
    y: root.panelTop
    Keys.onPressed: event => {
      if (event.key === Qt.Key_Escape) {
        if (!zoomOut()) root.bar.popup = "";
      } else if (event.key === Qt.Key_PageUp) moveZoom(-1);
      else if (event.key === Qt.Key_PageDown) moveZoom(1);
      else if (event.key === Qt.Key_Home) goToday();
      else return;
      event.accepted = true;
    }
  }
}
