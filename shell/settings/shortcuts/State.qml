pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import ".." as Settings

Singleton {
  id: root

  property var binds: []
  property var custom: []
  property string error: ""
  property var editing: null
  signal reloaded

  readonly property var ipcNames: ({
    "volume increase": "Raise Volume",
    "volume decrease": "Lower Volume",
    "volume muteOutput": "Mute Output",
    "volume muteInput": "Mute Microphone",
    "media playPause": "Play or Pause Media",
    "media next": "Next Track",
    "media previous": "Previous Track",
    "brightness increase": "Increase Brightness",
    "brightness decrease": "Decrease Brightness"
  })

  readonly property string userKeybinds: Quickshell.env("HOME") + "/.config/niri/cfg/keybinds.kdl"

  // The page mirrors whatever is on disk, so external edits show up live.
  FileView { path: root.userKeybinds; watchChanges: true; onFileChanged: root.refresh() }
  FileView {
    // Only watched once custom entries exist; the file may never be created.
    path: root.metaWatched ? Quickshell.env("HOME") + "/.config/pond-interface/shortcuts.json" : ""
    watchChanges: true
    onFileChanged: root.refresh()
  }
  property bool metaWatched: false
  Timer {
    // Saving touches both the keybinds file and the meta file.
    id: coalesce
    interval: 80
    onTriggered: load()
  }

  function refresh() { coalesce.restart(); }

  Component.onCompleted: load()

  readonly property var chipNames: ({
    "Mod": "spr", "Super": "spr", "Shift": "shift", "Ctrl": "ctrl", "ALT": "alt",
    "Return": "enter", "ESCAPE": "esc", "Backspace": "backspace",
    "WheelScrollUp": "scroll\u2191", "WheelScrollDown": "scroll\u2193",
    "WheelScrollLeft": "scroll\u2190", "WheelScrollRight": "scroll\u2192",
    "XF86AudioRaiseVolume": "vol+", "XF86AudioLowerVolume": "vol\u2212",
    "XF86AudioMute": "mute", "XF86AudioMicMute": "mic",
    "XF86AudioPlay": "play", "XF86AudioPause": "pause",
    "XF86AudioNext": "next", "XF86AudioPrev": "prev",
    "XF86MonBrightnessUp": "light+", "XF86MonBrightnessDown": "light\u2212",
    "Print": "print", "CapsLock": "caps", "Insert": "ins"
  })

  // What the keycaps spell out, as text: searching should match both the
  // label and the chips a user sees ("spr k" finds Switch Keyboard Language).
  // Modifier keys themselves, mapped to the chord name they stand for.
  readonly property var modifierKeys: ({
    [Qt.Key_Meta]: "Mod", [Qt.Key_Super_L]: "Mod", [Qt.Key_Super_R]: "Mod",
    [Qt.Key_Shift]: "Shift", [Qt.Key_Control]: "Ctrl",
    [Qt.Key_Alt]: "Alt", [Qt.Key_AltGr]: "Alt"
  })
  // niri binds name the unshifted key (Mod+Shift+Slash), while Qt reports
  // the shifted symbol; this folds a US layout back.
  readonly property var keyNames: ({
    [Qt.Key_Space]: "Space", [Qt.Key_Tab]: "Tab", [Qt.Key_Backtab]: "Tab",
    [Qt.Key_Return]: "Return", [Qt.Key_Enter]: "Return",
    [Qt.Key_Backspace]: "Backspace", [Qt.Key_Delete]: "Delete",
    [Qt.Key_Insert]: "Insert", [Qt.Key_Home]: "Home", [Qt.Key_End]: "End",
    [Qt.Key_PageUp]: "Page_Up", [Qt.Key_PageDown]: "Page_Down",
    [Qt.Key_Left]: "Left", [Qt.Key_Right]: "Right", [Qt.Key_Up]: "Up", [Qt.Key_Down]: "Down",
    [Qt.Key_Minus]: "Minus", [Qt.Key_Underscore]: "Minus",
    [Qt.Key_Equal]: "Equal", [Qt.Key_Plus]: "Equal",
    [Qt.Key_Slash]: "Slash", [Qt.Key_Question]: "Slash",
    [Qt.Key_Comma]: "Comma", [Qt.Key_Less]: "Comma",
    [Qt.Key_Period]: "Period", [Qt.Key_Greater]: "Period",
    [Qt.Key_Semicolon]: "Semicolon", [Qt.Key_Colon]: "Semicolon",
    [Qt.Key_Apostrophe]: "Apostrophe", [Qt.Key_QuoteDbl]: "Apostrophe",
    [Qt.Key_BracketLeft]: "BracketLeft", [Qt.Key_BraceLeft]: "BracketLeft",
    [Qt.Key_BracketRight]: "BracketRight", [Qt.Key_BraceRight]: "BracketRight",
    [Qt.Key_Backslash]: "Backslash", [Qt.Key_Bar]: "Backslash",
    [Qt.Key_QuoteLeft]: "Grave", [Qt.Key_AsciiTilde]: "Grave",
    [Qt.Key_Exclam]: "1", [Qt.Key_At]: "2", [Qt.Key_NumberSign]: "3", [Qt.Key_Dollar]: "4",
    [Qt.Key_Percent]: "5", [Qt.Key_AsciiCircum]: "6", [Qt.Key_Ampersand]: "7",
    [Qt.Key_Asterisk]: "8", [Qt.Key_ParenLeft]: "9", [Qt.Key_ParenRight]: "0",
    [Qt.Key_Print]: "Print",
    [Qt.Key_MediaPlay]: "XF86AudioPlay", [Qt.Key_MediaPause]: "XF86AudioPause",
    [Qt.Key_MediaStop]: "XF86AudioStop", [Qt.Key_MediaNext]: "XF86AudioNext",
    [Qt.Key_MediaPrevious]: "XF86AudioPrev",
    [Qt.Key_VolumeUp]: "XF86AudioRaiseVolume", [Qt.Key_VolumeDown]: "XF86AudioLowerVolume",
    [Qt.Key_VolumeMute]: "XF86AudioMute", [Qt.Key_MicMute]: "XF86AudioMicMute"
  })
  readonly property var order: ["Mod", "Shift", "Ctrl", "Alt", "Super"]

  // Chord recording, shared by the list and the editor. Returns the chord
  // ("Mod+Shift+K"), or null while only modifiers are held (staged then
  // holds them), or "" for a key niri can't bind.
  function readChord(event, held) {
    const modifier = modifierKeys[event.key];
    if (modifier !== undefined) {
      held(heldMods(event.modifiers, modifier, ""));
      return null;
    }
    const key = keySym(event);
    return key === "" ? "" : heldMods(event.modifiers, "", "").concat([key]).join("+");
  }

  // Whether an event's own modifier key is already in event.modifiers
  // varies by platform, so it is passed apart.
  function heldMods(modifiers, pressed, released) {
    const held = [];
    if (modifiers & Qt.MetaModifier) held.push("Mod");
    if (modifiers & Qt.ShiftModifier) held.push("Shift");
    if (modifiers & Qt.ControlModifier) held.push("Ctrl");
    if (modifiers & Qt.AltModifier) held.push("Alt");
    if (pressed && held.indexOf(pressed) < 0) held.push(pressed);
    return order.filter(mod => mod !== released && held.indexOf(mod) >= 0);
  }

  function keySym(event) {
    const key = event.key;
    if (key >= Qt.Key_A && key <= Qt.Key_Z) return String.fromCharCode(key);
    if (key >= Qt.Key_0 && key <= Qt.Key_9) return String.fromCharCode(key);
    if (key >= Qt.Key_F1 && key <= Qt.Key_F35) return "F" + (key - Qt.Key_F1 + 1);
    const name = keyNames[key];
    if (name !== undefined) return name;
    if (event.text && event.text.length === 1 && /[a-z0-9]/i.test(event.text))
      return event.text.toUpperCase();
    return "";
  }

  // Matches shortcuts.py: niri reads modifiers and keysyms case-insensitively.
  function canonical(key) {
    const upper = order.map(mod => mod.toUpperCase()), mods = [];
    let chord = "";
    for (const part of String(key).split("+")) {
      const index = upper.indexOf(part.toUpperCase());
      if (index >= 0) mods.push(index);
      else if (chord !== "") return "";
      else chord = part.toLowerCase();
    }
    return mods.sort().map(index => upper[index]).join("+") + "+" + chord;
  }

  // The bind already on a chord, ignoring the one being changed.
  function conflictWith(key, ignore) {
    const wanted = canonical(key);
    if (ignore && wanted === canonical(ignore)) return null;
    return binds.find(bind => canonical(bind.key) === wanted) || null;
  }

  function chipText(part) {
    return chipNames[part] !== undefined ? chipNames[part] : part.toLowerCase();
  }

  function chipsText(bind) {
    return String(bind.key).split("+").map(chipText).join(" ");
  }

  function label(bind) {
    if (bind.title) return bind.title;
    const text = String(bind.action || "");
    // Shell bindings call the Quickshell IPC by internal names ("volume",
    // "muteOutput"…); readers see those as noise, so name the concept.
    const call = text.match(/\"ipc\" \"call\" \"(\w+)\" \"(\w+)\"/);
    if (call && ipcNames[call[1] + " " + call[2]]) return ipcNames[call[1] + " " + call[2]];
    if (!text) return bind.key;
    const verb = text.replace(/;$/, "").split(" ")[0];
    if (verb === "spawn" || verb === "spawn-sh") {
      // The program (or script line) only, not every quoted argument.
      const program = text.match(/"((?:[^"\\]|\\.)*)"/);
      return "Run " + (program ? program[1].replace(/\\"/g, "\"") : text);
    }
    const rest = text.replace(/;$/, "").split(" ").slice(1).join(" ").replace(/"/g, "");
    return verb.split("-").map(word => word.charAt(0).toUpperCase() + word.slice(1)).join(" ")
        + (rest ? " " + rest : "");
  }

  function newShortcut() {
    editing = null;
    error = "";
    Settings.State.openPage("shortcutEditor");
  }

  function requestEditor(bind) {
    editing = Object.assign({}, bind);
    error = "";
    Settings.State.openPage("shortcutEditor");
  }

  // The backend swaps the old line for the new one in one step and rolls
  // back if the new chord is refused, so a failed edit keeps the old bind.
  function saveShortcut(originalKey, request, done, failed) {
    run(["save", originalKey, JSON.stringify(request)], () => {
      error = "";
      refresh();
      done();
    }, failure => { error = failure; if (failed) failed(); });
  }

  function rebind(oldKey, newKey, done, failed) {
    run(["rebind", oldKey, newKey], () => { error = ""; refresh(); if (done) done(); },
        failure => { error = failure; if (failed) failed(); });
  }

  function removeShortcut(key, done, failed) {
    run(["remove", key], () => { error = ""; refresh(); if (done) done(); },
        failure => { error = failure; if (failed) failed(); });
  }

  function load() {
    run(["list"], text => {
      try {
        const data = JSON.parse(text);
        binds = data.binds;
        custom = data.custom;
        metaWatched = metaWatched || data.custom.length > 0;
        error = "";
        reloaded();
      } catch (failure) { error = String(failure); }
    });
  }

  function run(args, success, failure) {
    queue.push({ args: args, success: success, failure: failure });
    if (!pending) drain();
  }

  function drain() {
    if (pending) return;
    const job = queue.shift();
    if (!job) return;
    pending = job;
    outputs = 0;
    runner.command = ["python3", Quickshell.shellDir + "/settings/shortcuts/shortcuts.py"].concat(job.args);
    runner.running = true;
  }

  // A job settles once both streams are collected and the process exited;
  // the exit code alone picks success or failure.
  function settle() {
    if (++outputs < 3) return;
    const job = pending;
    pending = null;
    if (exitCode === 0) { if (job.success) job.success(output.text); }
    else if (job.failure) job.failure(errors.text.trim() || "The shortcuts backend failed.");
    Qt.callLater(drain);
  }

  property var queue: []
  property var pending: null
  property int outputs: 0
  property int exitCode: 0

  Process {
    id: runner
    stdout: StdioCollector { id: output; onStreamFinished: root.settle() }
    stderr: StdioCollector { id: errors; onStreamFinished: root.settle() }
    onExited: code => { root.exitCode = code; root.settle(); }
  }
}
