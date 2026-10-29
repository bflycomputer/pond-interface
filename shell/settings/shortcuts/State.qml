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

  // Actions the editor offers. Spawn lines mirror config/niri/shell/config.kdl
  // so a fresh bind matches the built-in look on the hotkey overlay.
  readonly property var catalog: [
    {
      name: "Pond", items: [
        { label: "Open the launcher", action: "spawn \"/usr/bin/vicinae\" \"toggle\";" },
        { label: "Open clipboard history", action: "spawn \"/usr/bin/vicinae\" \"vicinae://launch/clipboard/history?toggle=true\";" },
        { label: "Toggle settings", action: "spawn \"qs\" \"-c\" \"pond-shell\" \"ipc\" \"call\" \"settings\" \"toggle\";" },
        { label: "Open keyboard shortcuts", action: "spawn \"qs\" \"-c\" \"pond-shell\" \"ipc\" \"call\" \"settings\" \"open\" \"shortcuts\";" },
        { label: "Open display settings", action: "spawn \"qs\" \"-c\" \"pond-shell\" \"ipc\" \"call\" \"settings\" \"open\" \"display\";" },
        { label: "Toggle the sidebar", action: "spawn \"qs\" \"-c\" \"pond-shell\" \"ipc\" \"call\" \"sidebar\" \"toggle\";" },
        { label: "Lock the screen", action: "spawn-sh \"/usr/bin/qs -p /usr/share/pond-interface/lockscreen ipc call lockscreen lock || /usr/bin/qs -d -p /usr/share/pond-interface/lockscreen\";" },
        { label: "Switch keyboard language", action: "switch-layout \"next\";" }
      ]
    },
    {
      name: "Windows", items: [
        { label: "Close focused window", action: "close-window;" },
        { label: "Fullscreen focused window", action: "fullscreen-window;" },
        { label: "Toggle window floating", action: "toggle-window-floating;" },
        { label: "Toggle column tabs", action: "toggle-column-tabbed-display;" },
        { label: "Expand column to available width", action: "expand-column-to-available-width;" },
        { label: "Center focused column", action: "center-column;" },
        { label: "Make column narrower", action: "set-column-width \"-10%\";" },
        { label: "Make column wider", action: "set-column-width \"+10%\";" }
      ]
    },
    {
      name: "Workspaces", items: [
        { label: "Move column left", action: "move-column-left;" },
        { label: "Move column right", action: "move-column-right;" },
        { label: "Focus previous workspace", action: "focus-workspace-previous;" },
        { label: "Focus next workspace", action: "focus-workspace-down;" },
        { label: "Move column to next workspace", action: "move-column-to-workspace-down;" }
      ]
    }
  ]

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
  function chipsText(bind) {
    return String(bind.key).split("+").map(part =>
        chipNames[part] !== undefined ? chipNames[part] : part.toLowerCase()).join(" ");
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
