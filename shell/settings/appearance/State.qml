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
  property string errorCode: ""
  property var errorParameters: []
  readonly property string error: errorCode ? errorParameters.reduce((text, parameter) => text.includes("%1") ? text.arg(parameter) : text, qsTrId(errorCode)) : ""
  signal keyboardBrightnessChanged(string outputName, real value)
  readonly property bool pickingWallpaper: picker.running
  readonly property bool busy: action.running
  readonly property bool active: Settings.State.opened && Settings.State.page === "appearance"
  readonly property bool brightnessAvailable: display.brightness !== undefined && display.brightness !== null
  readonly property string wallpaperName: wallpaperPath.split("/").pop() || ""

  onActiveChanged: {
    if (active) { expandedSection = ""; errorCode = ""; settleDelay.restart(); }
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
          if (result.error) { root.errorCode = result.error; errorParameters = result.errorParameters || []; return; }
          root.display = result;
          if (!root.draggingBrightness && root.pendingBrightness < 0 && !brightnessWriter.running && result.brightness !== null)
            root.brightness = result.brightness;
        } catch(e) { root.errorCode = "pond.could_not_read_display_settings"; }
      }
    }
  }
  Process {
    id: action
    stdout: StdioCollector {
      onStreamFinished: root.receive(text, "pond.could_not_apply_appearance_settings")
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
      onStreamFinished: root.receive(text, "pond.could_not_open_the_image_picker")
    }
  }
  Process {
    id: brightnessWriter
    property string outputName
    stdout: StdioCollector {
      onStreamFinished: root.receive(text, "pond.could_not_change_brightness")
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
      if (result.error) errorCode = result.error; errorParameters = result.errorParameters || [];
      if (result.theme) Shell.Theme.reload();
      if (result.mode) wallpaperFile.reload();
    } catch (exception) { errorCode = failure; }
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
    keyboardBrightnessChanged(output, value);
  }
  function toggleSection(section) { expandedSection = expandedSection === section ? "" : section; }
  function apply(args) {
    if (action.running) return;
    errorCode = "";
    action.command = ["python3", Quickshell.shellDir + "/settings/appearance/control.py"].concat(args);
    action.running = true;
  }
  function selectTheme(theme) {
    apply(["theme", theme]);
  }
  function selectDynamic() { apply(["wallpaper", "dynamic"]); }
  function pickWallpaper() { if (!picker.running) { errorCode = ""; picker.running = true; } }
  function setBrightness(value) {
    brightness = Math.max(0.01, Math.min(1, value));
    pendingBrightness = brightness;
    pendingBrightnessOutput = Settings.State.outputName;
    brightnessDelay.restart();
  }
  function flushBrightness() {
    if (brightnessWriter.running || pendingBrightness < 0) return;
    errorCode = "";
    brightnessWriter.outputName = pendingBrightnessOutput;
    brightnessWriter.command = ["python3", Quickshell.shellDir + "/settings/appearance/control.py", "brightness",
        pendingBrightnessOutput, String(pendingBrightness), cachedDevice(pendingBrightnessOutput)];
    pendingBrightness = -1;
    brightnessWriter.running = true;
  }
}
