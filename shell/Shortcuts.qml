import QtQuick
import Quickshell
import Quickshell.Io
import "audio" as Audio
import "media" as Media
import "settings" as Settings

Scope {
  id: root

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

  // Each request stays on the output that was focused when the key was pressed.
  function stepBrightness(direction, fine) {
    const output = Settings.State.focusedOutputName();
    if (output) Brightness.step(output, direction, fine);
  }
}
