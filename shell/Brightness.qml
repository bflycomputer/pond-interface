pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// The one path to the backlight, shared by the brightness keys, the sidebar
// card and the appearance slider. Writing a backlight can stall the display
// for about a second, so a change updates the level and whoever shows it at
// once, and the hardware only receives the final value of a burst: once the
// keys settle, or once a drag lets go.
Singleton {
  id: root
  // output -> {value, device, at}
  property var levels: ({})
  // output -> [{direction, fine}] pressed before the current level was known.
  property var queue: ({})
  // Outputs with a value the hardware hasn't received yet.
  property var dirty: ({})
  // Outputs being dragged; they write when released.
  property var held: ({})
  // A change is still waiting to reach a display.
  property bool busy: false
  readonly property string control: Quickshell.shellDir + "/settings/appearance/control.py"

  // Any change of level, from keys, the card or settings.
  signal levelChanged(string output, real value)
  // A key or wheel step on a level that is known; direction is ±1.
  signal stepped(string output, real value, int direction, bool fine)
  signal failed(string output, string error)

  function value(output) {
    const level = levels[output];
    return level ? level.value : -1;
  }

  // A reading from elsewhere (the settings page's status query). Ignored
  // while one of our own changes is still on its way.
  function seed(output, value, device) {
    if (dirty[output] || held[output] || writer.running && writer.outputName === output) return;
    const known = levels[output];
    levels[output] = {value: value, device: device || (known ? known.device : null), at: Date.now()};
  }

  function step(output, direction, fine) {
    const level = levels[output];
    // Re-read after a pause in case something else changed the brightness.
    const stale = level && Date.now() - level.at > 5000 && !dirty[output]
        && !(writer.running && writer.outputName === output);
    if (!level || stale) {
      queue[output] = (queue[output] || []).concat([{direction, fine}]);
      read();
      return;
    }
    const next = Math.max(0.01, PanelStyle.stepLevel(level.value, direction, fine));
    level.at = Date.now();
    // At either end the feedback still shows the press, but nothing is written.
    if (next !== level.value) change(output, next);
    stepped(output, next, direction, fine);
  }

  function set(output, value, device) {
    if (!output) return;
    const clamped = Math.max(0.01, Math.min(1, value));
    if (!levels[output]) levels[output] = {value: -1, device: device || null, at: 0};
    const level = levels[output];
    level.at = Date.now();
    if (device && !level.device) level.device = device;
    if (clamped !== level.value) change(output, clamped);
  }

  function hold(output, on) {
    if (!output) return;
    if (on) held[output] = true;
    else {
      delete held[output];
      settle.restart();
    }
  }

  function change(output, value) {
    levels[output].value = value;
    dirty[output] = true;
    settle.restart();
    sync();
    levelChanged(output, value);
  }

  function sync() {
    busy = writer.running || Object.keys(dirty).length > 0;
  }

  function read() {
    if (reader.running) return;
    const output = Object.keys(queue)[0];
    if (output === undefined) return;
    const level = levels[output];
    reader.outputName = output;
    reader.command = ["python3", control, "brightness-read", output,
        level && level.device ? JSON.stringify(level.device) : ""];
    reader.running = true;
  }

  function write() {
    if (writer.running) return;
    const output = Object.keys(dirty).find(output => !held[output]);
    if (output !== undefined) {
      delete dirty[output];
      const level = levels[output];
      writer.outputName = output;
      writer.command = ["python3", control, "brightness", output, String(level.value),
          level.device ? JSON.stringify(level.device) : ""];
      writer.running = true;
    }
    sync();
  }

  // Forget the output so the next press detects it again.
  function fail(output, error) {
    delete levels[output];
    delete dirty[output];
    sync();
    console.warn("Brightness:", error);
    failed(output, String(error));
  }

  // Key repeat arrives every ~40ms; write once the keys have settled.
  Timer { id: settle; interval: 200; onTriggered: root.write() }

  Process {
    id: reader
    property string outputName
    stdout: StdioCollector {
      onStreamFinished: {
        const output = reader.outputName;
        const steps = root.queue[output] || [];
        delete root.queue[output];
        try {
          const result = JSON.parse(text);
          if (result.error) throw result.error;
          root.levels[output] = {value: result.brightness, device: result.brightnessDevice, at: Date.now()};
          for (const step of steps) root.step(output, step.direction, step.fine);
        } catch (error) { root.fail(output, error); }
      }
    }
    onExited: Qt.callLater(root.read)
  }

  Process {
    id: writer
    property string outputName
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          const result = JSON.parse(text);
          if (result.error) throw result.error;
        } catch (error) { root.fail(writer.outputName, error); }
      }
    }
    onExited: Qt.callLater(root.write)
  }
}
