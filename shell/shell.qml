//@ pragma Env QSG_RENDER_LOOP = threaded
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "battery" as Battery
import "calendar" as Calendar
import "settings" as Settings
import "settings/appearance" as Appearance
import "settings/system" as System
import "notifications" as Notifications
import Pond.Wallpaper as Wallpaper
import Pond.System

ShellRoot {
  id: root
  property bool expanded: true

  Shortcuts {}

  Logind {
    id: logind
    sleepInhibited: true
    onPreparingForSleepChanged: {
      if (preparingForSleep)
        sleepLock.running = true;
      else
        sleepInhibited = true;
    }
    onLockRequested: Quickshell.execDetached(["python3", Quickshell.shellDir + "/settings/session.py", "lock"])
  }

  Variants {
    readonly property var commands: ({
      lock: ["python3", Quickshell.shellDir + "/settings/session.py", "lock"],
      display: ["niri", "msg", "action", "power-off-monitors"],
      sleep: ["python3", Quickshell.shellDir + "/settings/session.py", "suspend"]
    })
    model: Object.keys(commands).filter(key => System.Idle.current[key] > 0)
        .map(key => ({timeout: System.Idle.current[key], command: commands[key]}))
    delegate: IdleMonitor {
      required property var modelData
      timeout: modelData.timeout
      onIsIdleChanged: if (isIdle) Quickshell.execDetached(modelData.command)
    }
  }

  Process {
    id: sleepLock
    command: ["sh", "-c", "python3 \"$0\" lock; for _ in $(seq 40); do qs -p /usr/share/pond-interface/lockscreen ipc call lockscreen isSecure 2>/dev/null | grep -qx true && exit; sleep 0.1; done", Quickshell.shellDir + "/settings/session.py"]
    onExited: if (logind.preparingForSleep) logind.sleepInhibited = false
  }

  FileView {
    path: Quickshell.screens.length
        ? (Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state") + "/pond-interface/manual-shown"
        : ""
    printErrors: false
    onLoadFailed: error => {
      if (error !== FileViewError.FileNotFound) return;
      Settings.State.open("", "manual");
      Qt.callLater(() => setText("shown\n"));
    }
  }

  IpcHandler {
    target: "sidebar"
    function toggle() { root.expanded = !root.expanded; }
  }

  IpcHandler {
    target: "manual"
    function open() { Settings.State.open("", "manual"); }
  }

  IpcHandler {
    target: "settings"
    function toggle() { Settings.State.toggle(); }
    function open(page: string) {
      if (page && Settings.State.pages.indexOf(page) < 0) return;
      Settings.State.open("", page);
    }
    function close() { Settings.State.close(); }
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
      Notifications.ToastWindow { id: toast; bar: sidebar }
      Notifications.CenterWindow { bar: sidebar }
      Calendar.Window { bar: sidebar }
      Battery.Window { bar: sidebar }
      Battery.Notification { bar: sidebar; above: toast }
      PanelDismissWindow { bar: sidebar }
      Settings.Window { menuScreen: modelData }
    }
  }
}
