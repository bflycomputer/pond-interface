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
  property real pendingBrightness: -1
  property string pendingBrightnessOutput: ""
  property bool draggingBrightness: false
  property string error: ""
  readonly property bool pickingWallpaper: picker.running
  readonly property bool busy: action.running
  readonly property bool active: Settings.State.opened && Settings.State.page === "appearance"
  readonly property bool brightnessAvailable: display.brightness !== undefined && display.brightness !== null
  readonly property string wallpaperName: wallpaperPath.split("/").pop() || ""
  readonly property var scales: [1, 1.25, 1.5, 2]

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
          if (!root.draggingBrightness && root.pendingBrightness < 0 && !brightnessWriter.running && result.brightness !== null)
            root.brightness = result.brightness;
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
  Process {
    id: picker
    command: ["python3", Quickshell.shellDir + "/settings/appearance/control.py", "pick-wallpaper"]
    stdout: StdioCollector {
      onStreamFinished: root.receive(text, "Could not open the image picker")
    }
  }
  Process {
    id: brightnessWriter
    property string outputName
    stdout: StdioCollector {
      onStreamFinished: root.receive(text, "Could not change brightness")
    }
    onExited: (exitCode, exitStatus) => {
      if (exitCode !== 0 && outputName === root.display.output)
        root.display = Object.assign({}, root.display, {brightnessDevice: null});
      if (root.pendingBrightness >= 0) brightnessDelay.restart();
      else if (!root.draggingBrightness && exitCode !== 0) root.refresh();
    }
  }
  Timer { id: brightnessDelay; interval: 90; onTriggered: root.flushBrightness() }

  function receive(text, failure) {
    try {
      const result = JSON.parse(text);
      if (result.error) error = result.error;
      if (result.theme) Shell.Theme.reload();
      if (result.mode) wallpaperFile.reload();
    } catch (exception) { error = failure; }
  }
  function refresh() {
    if (query.running || brightnessWriter.running || draggingBrightness || !Settings.State.outputName) return;
    query.outputName = Settings.State.outputName;
    query.command = ["python3", Quickshell.shellDir + "/settings/appearance/control.py", "status", query.outputName,
        cachedDevice(query.outputName)];
    query.running = true;
  }
  function cachedDevice(output) {
    return display.output === output && display.brightnessDevice ? JSON.stringify(display.brightnessDevice) : "";
  }
  function receiveBrightness(output, value) {
    if (output === display.output && !draggingBrightness && pendingBrightness < 0 && !brightnessWriter.running)
      brightness = value;
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
  function selectScale(scale) { apply(["scale", Settings.State.outputName, String(scale)]); }
  function setBrightness(value) {
    brightness = Math.max(0.01, Math.min(1, value));
    pendingBrightness = brightness;
    pendingBrightnessOutput = Settings.State.outputName;
    brightnessDelay.restart();
  }
  function flushBrightness() {
    if (brightnessWriter.running || pendingBrightness < 0) return;
    error = "";
    brightnessWriter.outputName = pendingBrightnessOutput;
    brightnessWriter.command = ["python3", Quickshell.shellDir + "/settings/appearance/control.py", "brightness",
        pendingBrightnessOutput, String(pendingBrightness), cachedDevice(pendingBrightnessOutput)];
    pendingBrightness = -1;
    brightnessWriter.running = true;
  }
}
