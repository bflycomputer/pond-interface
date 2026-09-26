import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
  property alias custom: background.custom
  property alias imageSource: background.imageSource
  property alias now: background.now
  anchors { top: true; bottom: true; left: true; right: true }
  color: "#0b101c"
  WlrLayershell.namespace: "pond-wallpaper"
  WlrLayershell.layer: WlrLayer.Background
  exclusionMode: ExclusionMode.Ignore
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
  mask: Region {}

  Content {
    id: background
    anchors.fill: parent
  }
}
