import QtQuick
import Quickshell
import Quickshell.Io
import "calendar" as Calendar
import "notifications" as Notifications

ShellRoot {
  id: root
  property bool expanded: true

  IpcHandler {
    target: "sidebar"
    function toggle() { root.expanded = !root.expanded; }
  }

  Binding {
    target: NiriMsg
    property: "sidebarWidth"
    value: Theme.sidebarOuterMargin + (root.expanded
        ? Theme.sidebarCardExpandedWidth : Theme.sidebarCardCollapsedWidth)
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
    }
  }
}
