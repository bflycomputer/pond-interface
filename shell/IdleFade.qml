import QtQuick
import Quickshell
import Quickshell.Wayland
import "settings/system" as System

// Fades every screen to black once the display idle timeout passes, then
// powers the monitors off. Activity ends the idle state, which drops the fade.
Scope {
  id: root
  readonly property int duration: 5000

  IdleMonitor {
    id: idle
    enabled: timeout > 0
    timeout: System.Idle.current.display
  }

  Timer {
    interval: root.duration
    running: idle.isIdle
    onTriggered: Quickshell.execDetached(["niri", "msg", "action", "power-off-monitors"])
  }

  Variants {
    model: idle.isIdle ? Quickshell.screens : []
    PanelWindow {
      required property var modelData
      screen: modelData
      color: "transparent"
      anchors { left: true; right: true; top: true; bottom: true }
      WlrLayershell.layer: WlrLayer.Overlay
      WlrLayershell.namespace: "pond-idle-fade"
      WlrLayershell.exclusionMode: ExclusionMode.Ignore
      mask: Region {}
      ColorAnimation on color { to: "black"; duration: root.duration }
    }
  }
}
