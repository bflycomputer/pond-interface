//@ pragma Env QSG_RENDER_LOOP = threaded
import QtQuick
import Quickshell
import Quickshell.Io
import "calendar" as Calendar
import "settings" as Settings
import "settings/appearance" as Appearance
import "notifications" as Notifications
import Pond.Wallpaper as Wallpaper

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
      Wallpaper.Window {
        id: desktopWallpaper
        screen: modelData
        custom: Appearance.State.wallpaperMode === "custom"
        dimmed: Theme.daylight
        imageSource: Appearance.State.wallpaperUrl
      }
      Sidebar {
        id: sidebar
        screen: modelData
        expanded: root.expanded
        wallpaper: desktopWallpaper
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
