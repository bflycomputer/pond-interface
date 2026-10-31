pragma Singleton
import QtQuick
import ".." as Settings
import Quickshell
import Quickshell.Io

Singleton {
  id: root
  readonly property string helper: decodeURIComponent(Qt.resolvedUrl("control.py").toString().replace(/^file:\/\//, ""))
  property var languages: []
  property var timezones: []
  property var selectedLanguages: []
  property var languageNames: []
  property string timezone: ""
  property string timezoneLabel: ""
  property string error: ""
  property var mouse: ({speed: 0.5, scroll: 1, acceleration: true, naturalTouchpad: true, naturalMouse: false})
  readonly property bool busy: action.running
  readonly property bool active: Settings.State.opened && ["system", "mouse", "keyboard", "timezone"].indexOf(Settings.State.page) >= 0
  onActiveChanged: if (active) { error = ""; query.running = true; }
  Process {
    id: query
    command: ["python3", root.helper, "load"]
    stdout: StdioCollector { onStreamFinished: root.accept(text) }
  }
  Process {
    id: action
    stdout: StdioCollector { onStreamFinished: root.accept(text) }
  }
  Timer {
    id: mouseCommit
    interval: 300
    onTriggered: if (root.busy) restart(); else root.apply(["mouse", root.mouse.speed, root.mouse.scroll, root.mouse.acceleration, root.mouse.naturalTouchpad, root.mouse.naturalMouse].map(String))
  }
  function accept(text) {
    try {
      const result = JSON.parse(text);
      if (result.error) { error = result.error; return; }
      if (result.languages) languages = result.languages;
      if (result.timezones) timezones = result.timezones;
      if (timezone && timezone !== result.timezone) Date.timeZoneUpdated();
      selectedLanguages = result.selectedLanguages;
      languageNames = result.languageNames;
      timezone = result.timezone;
      timezoneLabel = result.timezoneLabel;
      if (!mouseCommit.running) mouse = result.mouse;
      error = "";
    } catch (e) { error = "Could not read system settings"; }
  }
  function apply(args) {
    if (busy) return;
    error = "";
    action.command = ["python3", root.helper].concat(args);
    action.running = true;
  }
  function toggleLanguage(id) { apply(["keyboard", id]); }
  function setTimezone(id) { if (id !== timezone) apply(["timezone", id]); }
  function setMouse(key, value) { mouse = Object.assign({}, mouse, {[key]: value}); mouseCommit.restart(); }
}
