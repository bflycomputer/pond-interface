//@ pragma Env QSG_RENDER_LOOP = threaded
import QtQuick
import Quickshell
import Quickshell.Io
import "calendar" as Calendar
import "settings" as Settings
import "notifications" as Notifications

ShellRoot {
  id: root
  property bool expanded: true

  Shortcuts {}

  IpcHandler {
    target: "sidebar"
    function toggle() { root.expanded = !root.expanded; }
  }

  Variants {
    model: Quickshell.screens
    delegate: Scope {
      required property var modelData
      Wallpaper { screen: modelData }
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
