pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
  id: root
  property ListModel jobs: ListModel {}

  function indexOf(id) {
    for (let i = 0; i < jobs.count; ++i) {
      if (jobs.get(i).jobId === id) return i;
    }
    return -1;
  }

  function update(id, name, status, percentage, message) {
    if (!id || !name || !["installing", "installed", "failed"].includes(status)
        || percentage < -1 || percentage > 100) return;
    const index = indexOf(id);
    const entry = {
      jobId: id, name: name, status: status,
      progress: percentage < 0 ? -1 : percentage / 100,
      message: message, finishedAt: status === "installed" ? Date.now() : 0
    };
    if (index < 0) jobs.append(entry);
    else jobs.set(index, entry);
  }

  function dismiss(id) {
    const index = indexOf(id);
    if (index >= 0 && jobs.get(index).status === "failed") jobs.remove(index);
  }

  IpcHandler {
    target: "installs"
    function update(id: string, name: string, status: string, percentage: int, message: string): void {
      root.update(id, name, status, percentage, message);
    }
  }

  Timer {
    interval: 250
    running: root.jobs.count > 0
    repeat: true
    onTriggered: {
      for (let i = root.jobs.count - 1; i >= 0; --i) {
        const job = root.jobs.get(i);
        if (job.status === "installed" && Date.now() - job.finishedAt >= 3000) jobs.remove(i);
      }
    }
  }
}
