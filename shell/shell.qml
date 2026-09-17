//@ pragma Env QSG_RENDER_LOOP = threaded
//@ pragma Env QSG_USE_SIMPLE_ANIMATION_DRIVER = 1
// Use elapsed time so multiple visible windows do not limit animations to 60 Hz.
import QtQuick
import Quickshell
import Quickshell.Io
import "calendar" as Calendar
import "settings" as Settings
import "notifications" as Notifications

ShellRoot {
  id: root
  property bool expanded: true

  IpcHandler {
    target: "sidebar"
    function toggle() { root.expanded = !root.expanded; }
  }

  Variants {
    model: Quickshell.screens
    delegate: Scope {
      required property var modelData
      Sidebar {
        id: sidebar
        screen: modelData
        expanded: root.expanded
        onToggleRequested: root.expanded = !root.expanded
      }
      Notifications.ToastWindow { bar: sidebar }
      Notifications.CenterWindow { bar: sidebar }
      Calendar.Window { bar: sidebar }
      PanelDismissWindow { bar: sidebar }
      Settings.Window { menuScreen: modelData }
    }
  }
}
