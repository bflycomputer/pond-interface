pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Singleton {
  id: root
  property ListModel jobs: ListModel {}
  property real lastResumeAt: 0

  function indexOf(id) {
    for (let i = 0; i < jobs.count; ++i) {
      if (jobs.get(i).jobId === id) return i;
    }
    return -1;
  }

  function active(status) { return status === "installing" || status === "uninstalling"; }
  function finished(status) { return status === "installed" || status === "uninstalled"; }

  function update(id, name, status, percentage, message, icon = "") {
    if (!id || !name || !(active(status) || finished(status) || status === "failed")
        || percentage < -1 || percentage > 100) return;
    const index = indexOf(id);
    const entry = {
      jobId: id, name: name, status: status,
      progress: percentage < 0 ? -1 : percentage / 100,
      message: message, icon: icon, finishedAt: finished(status) ? Date.now() : 0,
      removal: status === "failed" ? index >= 0 && jobs.get(index).removal
          : status.startsWith("uninstall")
    };
    if (index < 0) jobs.append(entry);
    else jobs.set(index, entry);
  }

  function dismiss(id) {
    const index = indexOf(id);
    if (index >= 0 && !active(jobs.get(index).status)) jobs.remove(index);
  }

  function findApp(name) {
    const wanted = name.toLowerCase();
    const matches = DesktopEntries.applications.values.filter(entry =>
        !entry.runInTerminal && entry.command.length > 0 && entry.name.toLowerCase() === wanted);
    return matches.length === 1 ? matches[0] : null;
  }

  function launch(id) {
    const index = indexOf(id);
    const app = index < 0 ? null : findApp(jobs.get(index).name);
    if (!app) return;
    app.execute();
    jobs.remove(index);
  }

  IpcHandler {
    target: "installs"
    function update(id: string, name: string, status: string, percentage: int, message: string,
        icon: string): void {
      root.update(id, name, status, percentage, message, icon);
    }
  }

  IdleMonitor {
    id: idleMonitor
    timeout: 20
    respectInhibitors: false
    onIsIdleChanged: if (!isIdle) root.lastResumeAt = Date.now()
  }

  Timer {
    interval: 250
    running: root.jobs.count > 0 && !idleMonitor.isIdle
    repeat: true
    onTriggered: {
      for (let i = root.jobs.count - 1; i >= 0; --i) {
        const job = root.jobs.get(i);
        if (root.finished(job.status)
            && Date.now() - Math.max(job.finishedAt, root.lastResumeAt) >= 30000) root.jobs.remove(i);
      }
    }
  }
}
