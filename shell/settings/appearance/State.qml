pragma Singleton
import QtQuick
import QtCore
import ".." as Settings
import "../.." as Shell
import Quickshell
import Quickshell.Io

Singleton {
  id: root
  property string expandedSection: ""
  property string wallpaperMode: "dynamic"
  property string wallpaperPath: ""
  property string wallpaperUrl: ""
  property var display: ({})
  property real brightness: 1
  property bool draggingBrightness: false
  property string error: ""
  readonly property bool pickingWallpaper: picker.running
  readonly property bool busy: action.running
  readonly property bool active: Settings.State.opened && Settings.State.page === "appearance"
  readonly property bool brightnessAvailable: display.brightness !== undefined && display.brightness !== null
  readonly property string wallpaperName: wallpaperPath.split("/").pop() || ""

  onActiveChanged: {
    if (active) { expandedSection = ""; error = ""; settleDelay.restart(); }
    else settleDelay.stop();
  }
  // DDC/CI brightness reads stall the GPU's display driver for a few hundred
  // ms, freezing every animating window. Only query once the page is static.
  Timer { id: settleDelay; interval: Settings.Style.closeDuration + 60; onTriggered: root.refresh() }
  Connections {
    target: Settings.State
    function onOutputNameChanged() { root.display = ({}); if (root.active) root.refresh(); }
  }
  // Writes go through Shell.Brightness, so keys, the sidebar card and this
  // page share one level and one writer.
  onDraggingBrightnessChanged: Shell.Brightness.hold(Settings.State.outputName, draggingBrightness)
  Connections {
    target: Shell.Brightness
    function onLevelChanged(output, value) {
      if (output === root.display.output) root.brightness = value;
    }
    function onFailed(output, error) {
      if (output !== root.display.output) return;
      root.error = "Could not change brightness";
      root.display = Object.assign({}, root.display, {brightnessDevice: null});
      if (!root.draggingBrightness) root.refresh();
    }
  }
  FileView {
    id: wallpaperFile
    path: StandardPaths.writableLocation(StandardPaths.ConfigLocation) + "/pond-interface/wallpaper.json"
    printErrors: false
    watchChanges: true
    onFileChanged: reload()
    onLoaded: {
      try {
        const state = JSON.parse(text());
        root.wallpaperMode = state.mode === "custom" ? "custom" : "dynamic";
        root.wallpaperPath = state.path || "";
        root.wallpaperUrl = state.url || "";
      } catch(e) { console.warn("Appearance wallpaper:", e); }
    }
  }
  Process {
    id: query
    property string outputName
    onExited: if (root.active && outputName !== Settings.State.outputName) root.refresh()
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          const result = JSON.parse(text);
          if (query.outputName !== Settings.State.outputName) return;
          if (result.error) { root.error = result.error; return; }
          root.display = result;
          if (!root.draggingBrightness && result.brightness !== null) {
            Shell.Brightness.seed(result.output, result.brightness, result.brightnessDevice);
            root.brightness = Shell.Brightness.value(result.output);
          }
        } catch(e) { root.error = "Could not read display settings"; }
      }
    }
  }
  Process {
    id: action
    stdout: StdioCollector {
      onStreamFinished: root.receive(text, "Could not apply appearance settings")
    }
    onExited: root.refresh()
  }
  FileView {
    path: StandardPaths.writableLocation(StandardPaths.ConfigLocation) + "/background"
    printErrors: false
    watchChanges: true
    onFileChanged: root.apply(["wallpaper", "custom", decodeURIComponent(path.replace(/^file:\/\//, ""))])
  }
  Process {
    id: picker
    command: ["python3", Quickshell.shellDir + "/settings/appearance/control.py", "pick-wallpaper"]
    stdout: StdioCollector {
      onStreamFinished: root.receive(text, "Could not open the image picker")
    }
  }

  function receive(text, failure) {
    try {
      const result = JSON.parse(text);
      if (result.error) error = result.error;
      if (result.theme) Shell.Theme.reload();
      if (result.mode) wallpaperFile.reload();
    } catch (exception) { error = failure; }
  }
  function refresh() {
    if (query.running || Shell.Brightness.busy || draggingBrightness || !Settings.State.outputName) return;
    query.outputName = Settings.State.outputName;
    query.command = ["python3", Quickshell.shellDir + "/settings/appearance/control.py", "status", query.outputName,
        cachedDevice(query.outputName)];
    query.running = true;
  }
  function cachedDevice(output) {
    return display.output === output && display.brightnessDevice ? JSON.stringify(display.brightnessDevice) : "";
  }
  function toggleSection(section) { expandedSection = expandedSection === section ? "" : section; }
  function apply(args) {
    if (action.running) return;
    error = "";
    action.command = ["python3", Quickshell.shellDir + "/settings/appearance/control.py"].concat(args);
    action.running = true;
  }
  function selectTheme(theme) {
    apply(["theme", theme]);
  }
  function selectDynamic() { apply(["wallpaper", "dynamic"]); }
  function pickWallpaper() { if (!picker.running) { error = ""; picker.running = true; } }
  function setBrightness(value) {
    error = "";
    Shell.Brightness.set(Settings.State.outputName, value, display.brightnessDevice);
  }
}
