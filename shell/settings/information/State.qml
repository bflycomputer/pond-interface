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
    stdout: StdioCollector {
      onStreamFinished: {
        try { root.facts = Object.assign({}, root.facts, JSON.parse(text)); }
        catch(e) { console.warn("Information: could not read system facts", e); }
      }
    }
  }
  Timer { interval: 3000; repeat: true; running: root.active; onTriggered: root.refresh(true) }

  function refresh(usageOnly) {
    if (query.running) return;
    query.command = ["python3", Quickshell.shellDir + "/settings/information/system.py"].concat(usageOnly ? ["--usage"] : []);
    query.running = true;
  }
  function value(key) { return facts[key] || "…"; }
}
