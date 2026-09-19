import QtQuick
import Quickshell
import Quickshell.Io
import "audio" as Audio
import "media" as Media
import "settings" as Settings
import "settings/appearance" as Appearance

Scope {
  id: root
  property var brightnessQueue: ({})

  IpcHandler {
    target: "volume"
    function increase(): void { Audio.State.adjustOutputVolume(0.02); }
    function decrease(): void { Audio.State.adjustOutputVolume(-0.02); }
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
    function increase(): void { root.adjustBrightness(0.05); }
    function decrease(): void { root.adjustBrightness(-0.05); }
  }

  function adjustBrightness(delta) {
    const output = Settings.State.focusedOutputName();
    if (!output) return;
    // Coalesce key repeats while a DDC read/write is in flight. Keep each
    // request on the output that was focused when the key was pressed.
    brightnessQueue[output] = (brightnessQueue[output] || 0) + delta;
    flushBrightness();
  }

  function flushBrightness() {
    if (brightness.running) return;
    const output = Object.keys(brightnessQueue)[0];
    if (output === undefined) return;
    const delta = brightnessQueue[output];
    delete brightnessQueue[output];
    brightness.outputName = output;
    brightness.command = ["python3", Quickshell.shellDir + "/settings/appearance/control.py",
        "brightness-step", output, String(delta)];
    brightness.running = true;
  }

  Process {
    id: brightness
    property string outputName
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          const result = JSON.parse(text);
          if (result.error) console.warn("Brightness shortcut:", result.error);
          else Appearance.State.receiveBrightness(brightness.outputName, result.brightness);
        } catch (error) { console.warn("Brightness shortcut:", error); }
      }
    }
    onExited: Qt.callLater(root.flushBrightness)
  }
}
