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
  readonly property var toggles: [
    { label: "Repeat while held", flag: "repeat" },
    { label: "Also when the screen is locked", flag: "allow-when-locked" }
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

  function label(bind) {
    if (bind.title) return bind.title;
    if (!bind.action) return bind.key;
    const verb = bind.action.replace(/;$/, "").split(" ")[0];
    if (verb === "spawn" || verb === "spawn-sh") {
      const literal = bind.action.slice(bind.action.indexOf("\"") + 1, bind.action.lastIndexOf("\""));
      return "Run " + literal;
    }
    const rest = bind.action.replace(/;$/, "").split(" ").slice(1).join(" ");
    return verb.split("-").map(word => word.charAt(0).toUpperCase() + word.slice(1)).join(" ")
        + (rest ? " " + rest : "");
  }

  function chips(key) { return String(key).split("+"); }

  function newShortcut() {
    editing = null;
    Settings.State.openPage("shortcutEditor");
  }

  function requestEditor(bind) {
    editing = Object.assign({}, bind);
    Settings.State.openPage("shortcutEditor");
  }

  function saveShortcut(originalKey, request, done) {
    // Custom binds are rewritten: remove the previous line, then add the new
    // one. Removal may fail when the chord never made it to disk; continue.
    const commit = () => run(["add", JSON.stringify(request)], result => {
      error = "";
      load();
      done();
    }, failure => { error = failure; });
    if (originalKey) run(["remove", originalKey], commit, commit);
    else commit();
  }

  function removeShortcut(key, done) {
    run(["remove", key], () => { error = ""; load(); if (done) done(); },
        failure => { error = failure; });
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
    if (!runner.running) drain();
  }

  function drain() {
    const job = queue.shift();
    if (!job) return;
    pending = job;
    runner.command = ["python3", Quickshell.shellDir + "/settings/shortcuts/shortcuts.py"].concat(job.args);
    runner.running = true;
  }

  property var queue: []
  property var pending: null

  Process {
    id: runner
    stdout: StdioCollector {
      onStreamFinished: {
        if (root.pending && root.pending.success) root.pending.success(text);
      }
    }
    stderr: StdioCollector {
      onStreamFinished: {
        const failure = text.trim();
        if (failure && root.pending && root.pending.failure) root.pending.failure(failure);
      }
    }
    onExited: Qt.callLater(drain)
  }
}
