pragma ComponentBehavior: Bound
import QtQuick
import QtCore
import Quickshell.Io
import Quickshell
import Quickshell.Wayland
import Pond.Daylight

ShellRoot {
    id: root
    readonly property var wallpaper: {
        try { return JSON.parse(wallpaperFile.text() || "{}"); }
        catch (error) { console.warn("Could not read wallpaper settings:", error); return {}; }
    }
    IpcHandler {
        target: "wallpaper"
        function reload(): void { wallpaperFile.reload(); }
    }
    FileView {
        id: wallpaperFile
        path: StandardPaths.writableLocation(StandardPaths.ConfigLocation) + "/pond-interface/wallpaper.json"
        printErrors: false
        watchChanges: true
        onFileChanged: reload()
    }
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

            Loader {
                anchors.fill: parent
                active: root.wallpaper.mode !== "custom"
                sourceComponent: Sky {}
            }
            Image {
                anchors.fill: parent
                source: root.wallpaper.mode === "custom" ? root.wallpaper.url || "" : ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
            }
        }
    }
}
