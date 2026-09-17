pragma Singleton
import QtQuick
import ".." as Settings
import Quickshell
import Quickshell.Io

Singleton {
  id: root
  property var facts: ({})
  readonly property bool active: Settings.State.opened && Settings.State.page === "information"
  onActiveChanged: if (active) refresh(false)

  Process {
    id: query
    property bool usageOnly: false
    command: ["fastfetch", "--config", "-", "--format", "json"]
    onStarted: {
      const modules = usageOnly ? ["Memory"] : ["OS", "Title", "Board", "CPU", "GPU", "Memory"];
      write(JSON.stringify({modules: modules.concat([{type: "disk", folders: "/", useAvailable: false}])}));
      stdinEnabled = false;
    }
    stdout: StdioCollector {
      onStreamFinished: {
        try { root.updateFacts(text, query.usageOnly); }
        catch(e) { console.warn("Information: could not read system facts", e); }
      }
    }
  }
  Timer { interval: 3000; repeat: true; running: root.active; onTriggered: root.refresh(true) }

  function refresh(usageOnly) {
    if (query.running) return;
    query.usageOnly = usageOnly;
    query.stdinEnabled = true;
    query.running = true;
  }
  function usage(bytes) {
    return bytes?.total > 0
        ? `${(bytes.used / 2 ** 30).toFixed(1)} GiB / ${(bytes.total / 2 ** 30).toFixed(1)} GiB`
        : "Unavailable";
  }
  function updateFacts(text, usageOnly) {
    const data = {};
    for (const item of JSON.parse(text)) data[item.type] = item.result;
    const next = {memory: usage(data.Memory), disk: usage(data.Disk?.[0]?.bytes)};
    if (!usageOnly) {
      const threads = data.CPU?.cores?.online;
      Object.assign(next, {
        os: data.OS?.prettyName || data.OS?.name || "Unavailable",
        host: data.Title?.hostName || "Unavailable",
        board: data.Board?.name || "Unavailable",
        cpu: data.CPU?.cpu ? `${data.CPU.cpu.replace(/\s+\d+-Core Processor$/, "")} (${threads} ${threads === 1 ? "Thread" : "Threads"})` : "Unavailable",
        gpu: [...new Set((data.GPU || []).map(gpu => gpu.name).filter(Boolean))].join(", ") || "Unavailable"
      });
    }
    facts = Object.assign({}, facts, next);
  }
  function value(key) { return facts[key] || "…"; }
}
