pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Wayland
import Pond.Daylight

ShellRoot {
    Variants {
        model: Quickshell.screens
        PanelWindow {
            required property ShellScreen modelData
            screen: modelData
            anchors { top: true; bottom: true; left: true; right: true }
            color: "#0b101c"
            WlrLayershell.namespace: "daylight-wallpaper"
            // Background surfaces can stay fixed in niri's overview backdrop.
            WlrLayershell.layer: WlrLayer.Background
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            mask: Region {}

            Sky { anchors.fill: parent }
        }
    }
}
