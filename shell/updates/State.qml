pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../installs" as Installs
import "../settings" as Settings

Singleton {
  id: root
  property string status: ""
  property string pending: ""

  function start() {
    if (status !== "available") return;
    pending = "";
    Settings.State.close();
    Quickshell.execDetached(["sh", "-c", 'rm -f "$1.after"; echo updating > "$1"; '
        + 'pm -u; case $? in 0) echo complete ;; 2) echo restart ;; *) echo failed ;; esac > "$1"; '
        + 'action=$(cat "$1.after" 2>/dev/null) && [ -n "$action" ] && python3 "$2" "$action"',
      "sh", statusFile.path, Quickshell.shellDir + "/settings/session.py"]);
  }

  function after(action) {
    pending = pending === action ? "" : action;
    afterFile.setText(pending);
  }

  Timer {
    interval: 12 * 60 * 60 * 1000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: check.running = true
  }

  Process {
    id: check
    command: ["pm", "-a"]
    stdout: StdioCollector { id: output }
    onExited: exitCode => {
      if (exitCode === 0 && (root.status === "" || root.status === "available"))
        root.status = output.text.trim() === "true" ? "available" : "";
    }
  }

  Timer {
    interval: 60 * 60 * 1000
    running: root.status === "complete"
    onTriggered: root.status = ""
  }

  FileView {
    id: statusFile
    path: Quickshell.env("XDG_RUNTIME_DIR") + "/pond-update"
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: {
      const result = text().trim();
      const wasUpdating = root.status === "updating";
      if (result === "updating") {
        root.status = "updating";
        Installs.State.update("system-update", qsTrId("pond.updating"), "installing", -1, "");
      } else if (result === "restart") {
        root.status = "restart";
        if (wasUpdating) Installs.State.update("system-update", qsTrId("pond.update_complete"), "installed", -1, "");
      } else if (wasUpdating && result === "complete") {
        root.status = "complete";
        Installs.State.update("system-update", qsTrId("pond.update_complete"), "installed", -1, "");
      } else if (wasUpdating && result === "failed") {
        root.status = "available";
        Installs.State.update("system-update", qsTrId("pond.update_failed"), "failed", -1, "");
      }
    }
  }

  FileView {
    id: afterFile
    path: statusFile.path + ".after"
    printErrors: false
    onLoaded: root.pending = text().trim()
  }
}
