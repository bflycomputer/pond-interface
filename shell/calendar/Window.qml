pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Wayland
import "." as Calendar
import "../notifications" as Notifications
import ".." as Shell

PanelWindow {
  id: root
  required property var bar
  readonly property real panelLeft: Shell.Theme.sidebarOuterMargin + bar.cardWidth + 10
  readonly property real panelTop: Shell.Theme.sidebarOuterMargin

  screen: bar.screen
  visible: bar.calendarOpen
  color: "transparent"
  anchors { left: true; right: true; top: true; bottom: true }
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.namespace: "pond-calendar-" + (screen ? screen.name : "unknown")
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
  WlrLayershell.exclusionMode: ExclusionMode.Ignore

  // Ask the compositor to blur only the rounded calendar, not the click catcher.
  BackgroundEffect.blurRegion: Region {
    x: calendar.x
    y: calendar.y
    width: calendar.width
    height: calendar.height
    radius: 24
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
    onClicked: root.bar.calendarOpen = false
  }

  Calendar.Card {
    id: calendar
    x: root.panelLeft
    y: root.panelTop
    Keys.onPressed: event => {
      if (event.key === Qt.Key_Escape) root.bar.calendarOpen = false;
      else if (event.key === Qt.Key_PageUp) moveMonth(-1);
      else if (event.key === Qt.Key_PageDown) moveMonth(1);
      else if (event.key === Qt.Key_Home) goToday();
      else return;
      event.accepted = true;
    }
  }

  Connections {
    target: Notifications.State
    function onPanelOpenChanged() { if (Notifications.State.panelOpen) root.bar.calendarOpen = false; }
  }
}
