import QtQuick
import Quickshell
import Quickshell.Io
import "audio" as Audio
import "media" as Media
import "settings" as Settings
import "settings/appearance" as Appearance

Scope {
  id: root
  // output -> {value, device, at}. Writing a backlight can stall the display
  // for about a second, so key presses update this level and the feedback at
  // once, and the hardware only receives the final value of a burst.
  property var brightnessLevels: ({})
  // output -> [{direction, fine}] pressed before the current level was known.
  property var brightnessQueue: ({})
  property var brightnessDirty: ({})

  IpcHandler {
    target: "volume"
    function increase(): void { Audio.State.stepOutputVolume(1, false); }
    function decrease(): void { Audio.State.stepOutputVolume(-1, false); }
    function increaseFine(): void { Audio.State.stepOutputVolume(1, true); }
    function decreaseFine(): void { Audio.State.stepOutputVolume(-1, true); }
    function muteOutput(): void { Audio.State.toggleOutputMute(); }
    function muteInput(): void { Audio.State.toggleInputMute(); }
  }
  IpcHandler {
    target: "media"
    function playPause(): void { Media.State.shortcut("playPause"); }
    function next(): void { Media.State.shortcut("next"); }
    function previous(): void { Media.State.shortcut("previous"); }
  }
  IpcHandler {
    target: "brightness"
    function increase(): void { root.stepBrightness(1, false); }
    function decrease(): void { root.stepBrightness(-1, false); }
    function increaseFine(): void { root.stepBrightness(1, true); }
    function decreaseFine(): void { root.stepBrightness(-1, true); }
  }

  // The settings slider may have moved the level since the last key press.
  Connections {
    target: Appearance.State
    function onBrightnessChanged() {
      const output = Appearance.State.display.output;
      const level = root.brightnessLevels[output];
      const writing = root.brightnessDirty[output] || writer.running && writer.outputName === output;
      if (level && !writing) level.value = Appearance.State.brightness;
    }
  }

  function stepBrightness(direction, fine) {
    const output = Settings.State.focusedOutputName();
    if (output) stepOutputBrightness(output, direction, fine);
  }

  function stepOutputBrightness(output, direction, fine) {
    const level = brightnessLevels[output];
    // Re-read after a pause in case something else changed the brightness.
    if (!level || Date.now() - level.at > 5000) {
      brightnessQueue[output] = (brightnessQueue[output] || []).concat([{direction, fine}]);
      readBrightness();
      return;
    }
    const value = Math.max(0.01, PanelStyle.stepLevel(level.value, direction, fine));
    level.at = Date.now();
    // At either end the feedback still shows the press, but nothing is written.
    if (value !== level.value) {
      level.value = value;
      brightnessDirty[output] = true;
      brightnessSettle.restart();
      syncBrightnessBusy();
    }
    Appearance.State.receiveBrightness(output, value, direction, fine);
  }

  function syncBrightnessBusy() {
    Appearance.State.keyboardBrightnessBusy = writer.running || Object.keys(brightnessDirty).length > 0;
  }

  function readBrightness() {
    if (reader.running) return;
    const output = Object.keys(brightnessQueue)[0];
    if (output === undefined) return;
    const level = brightnessLevels[output];
    reader.outputName = output;
    reader.command = ["python3", Quickshell.shellDir + "/settings/appearance/control.py",
        "brightness-read", output, level ? JSON.stringify(level.device) : ""];
    reader.running = true;
  }

  function writeBrightness() {
    if (writer.running) return;
    const output = Object.keys(brightnessDirty)[0];
    if (output === undefined) { syncBrightnessBusy(); return; }
    delete brightnessDirty[output];
    const level = brightnessLevels[output];
    writer.outputName = output;
    writer.command = ["python3", Quickshell.shellDir + "/settings/appearance/control.py",
        "brightness", output, String(level.value), JSON.stringify(level.device)];
    writer.running = true;
    syncBrightnessBusy();
  }

  // Key repeat arrives every ~40ms; write once the keys have settled.
  Timer { id: brightnessSettle; interval: 200; onTriggered: root.writeBrightness() }

  Process {
    id: reader
    property string outputName
    stdout: StdioCollector {
      onStreamFinished: {
        const output = reader.outputName;
        const steps = root.brightnessQueue[output] || [];
        delete root.brightnessQueue[output];
        try {
          const result = JSON.parse(text);
          if (result.error) throw result.error;
          root.brightnessLevels[output] = {value: result.brightness, device: result.brightnessDevice, at: Date.now()};
          for (const step of steps) root.stepOutputBrightness(output, step.direction, step.fine);
        } catch (error) {
          delete root.brightnessLevels[output];
          console.warn("Brightness shortcut:", error);
        }
      }
    }
    onExited: Qt.callLater(root.readBrightness)
  }

  Process {
    id: writer
    property string outputName
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          const result = JSON.parse(text);
          if (result.error) throw result.error;
        } catch (error) {
          // Forget the device so the next press detects it again.
          delete root.brightnessLevels[writer.outputName];
          console.warn("Brightness shortcut:", error);
        }
      }
    }
    onExited: Qt.callLater(root.writeBrightness)
  }
}
