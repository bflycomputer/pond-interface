import QtQuick
import Quickshell
import Quickshell.Wayland
import Pond.Daylight
import "settings/appearance" as Appearance

// The shell owns the background surface and saved selection. Daylight only
// supplies the dynamic scene, just as Image supplies a custom background.
PanelWindow {
  anchors { top: true; bottom: true; left: true; right: true }
  color: "#0b101c"
  WlrLayershell.namespace: "pond-wallpaper"
  WlrLayershell.layer: WlrLayer.Background
  exclusionMode: ExclusionMode.Ignore
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
  mask: Region {}

  Loader {
    anchors.fill: parent
    active: Appearance.State.wallpaperMode !== "custom"
    sourceComponent: Sky {}
  }
  Image {
    objectName: "wallpaperImage"
    anchors.fill: parent
    source: Appearance.State.wallpaperMode === "custom" ? Appearance.State.wallpaperUrl : ""
    fillMode: Image.PreserveAspectCrop
    asynchronous: true
  }
}
