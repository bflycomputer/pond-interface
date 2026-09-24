pragma Singleton
import QtQuick
import "." as Display
import ".." as Settings
import "../.." as Shell
import Quickshell
import Quickshell.Io

Singleton {
  id: root
  readonly property string helper: decodeURIComponent(Qt.resolvedUrl("control.py").toString().replace(/^file:\/\//, ""))
  property var monitors: []
  property var geometry: []
  property string selectedName: ""
  property string error: ""
  property bool queryFailed: false
  property bool loaded: false
  property int revision: 0
  property bool pendingRefresh: false
  readonly property bool active: Settings.State.opened && ["appearance", "display", "arrange"].indexOf(Settings.State.page) >= 0
  readonly property bool busy: action.running
  readonly property var selected: monitors.find(m => m.name === selectedName) || null
  readonly property string summary: !loaded ? "Loading…" : monitors.length > 1 ? monitors.length + " monitors" : monitors.length ? monitors[0].label : "No displays"
  signal arrangementApplied
  onActiveChanged: if (active) { error = ""; refresh(); }
  Connections {
    target: Quickshell
    function onScreensChanged() { root.refresh(); }
  }
  Process {
    id: query
    property int revision: 0
    command: ["python3", root.helper, "status"]
    stdout: StdioCollector {
      onStreamFinished: {
        if (root.busy || query.revision !== root.revision) return;
        try { root.accept(JSON.parse(text), true); }
        catch(e) { root.error = "Could not read connected displays"; root.queryFailed = true; }
      }
    }
    onExited: if (root.pendingRefresh) { root.pendingRefresh = false; Qt.callLater(root.refresh); }
  }
  Process {
    id: action
    property bool arranging: false
    property bool succeeded: false
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          const result = JSON.parse(text);
          root.accept(result);
          action.succeeded = !result.error;
        } catch(e) { root.error = "Could not apply display settings"; root.queryFailed = false; }
      }
    }
    onExited: {
      if (arranging && succeeded) root.arrangementApplied();
      root.refresh();
    }
  }
  Timer { interval: 1500; running: root.active; repeat: true; onTriggered: root.refresh() }
  function accept(result, fromQuery = false) {
    if (result.error) { error = result.error; queryFailed = fromQuery; return; }
    if (!result.monitors) return;
    if (!fromQuery || queryFailed) error = "";
    queryFailed = false;
    if (JSON.stringify(monitors) !== JSON.stringify(result.monitors)) monitors = result.monitors;
    if (JSON.stringify(geometry) !== JSON.stringify(result.geometry)) geometry = result.geometry;
    loaded = true;
    if (monitors.length && Settings.State.outputName && !monitors.some(m => m.name === Settings.State.outputName))
      Settings.State.outputName = monitors[0].name;
    if (!monitors.some(m => m.name === selectedName)) {
      selectedName = monitors.some(m => m.name === Settings.State.outputName) ? Settings.State.outputName : monitors.length ? monitors[0].name : "";
    }
  }
  function refresh() {
    if (query.running) { pendingRefresh = true; return; }
    if (!action.running) { query.revision = revision; query.running = true; }
  }
  function select(name) { if (!busy) { selectedName = name; error = ""; } }
  function apply(args, arranging) {
    if (busy) return;
    revision += 1; error = ""; action.arranging = !!arranging; action.succeeded = false;
    action.command = ["python3", root.helper].concat(args);
    action.running = true;
  }
  function change(field, value) { if (selected) apply([field, selected.name, String(value), selected.identity], false); }
  function arrange(baseline, positions) {
    apply(["arrange", JSON.stringify({baseline:baseline,positions:positions.map(r=>({name:r.name,x:r.x,y:r.y}))})], true);
  }
}
