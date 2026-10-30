pragma Singleton
import Pond.Localization
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
  function usage(used, total) {
    return total > 0 ? qsTrId("pond.1_gib_2_gib").arg(Localization.number(used / 2 ** 30, 1)).arg(Localization.number(total / 2 ** 30, 1)) : qsTrId("pond.unavailable");
  }
  function updateFacts(text, usageOnly) {
    const data = {};
    for (const item of JSON.parse(text)) data[item.type] = item.result;
    const disk = data.Disk?.[0]?.bytes;
    const next = {memoryUsed: data.Memory?.used, memoryTotal: data.Memory?.total, diskUsed: disk?.total - disk?.free, diskTotal: disk?.total};
    if (!usageOnly) Object.assign(next, {
      os: data.OS?.prettyName || data.OS?.name,
      host: data.Title?.hostName, board: data.Board?.name,
      cpu: data.CPU?.cpu?.replace(/\s+\d+-Core Processor$/, ""), threads: data.CPU?.cores?.online,
      gpu: [...new Set((data.GPU || []).map(gpu => gpu.name).filter(Boolean))].join(", ")
    });
    facts = Object.assign({}, facts, next);
  }
  function value(key) {
    if (key === "memory") return usage(facts.memoryUsed, facts.memoryTotal);
    if (key === "disk") return usage(facts.diskUsed, facts.diskTotal);
    if (key === "cpu" && facts.cpu) return facts.cpu + " (" + qsTrId("hardware.threads", facts.threads || 0) + ")";
    return facts[key] || qsTrId("pond.unavailable");
  }
}
