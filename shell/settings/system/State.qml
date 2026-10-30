pragma Singleton
import Pond.Localization
import QtQuick
import ".." as Settings
import Quickshell
import Quickshell.Io

Singleton {
  id: root
  readonly property string helper: decodeURIComponent(Qt.resolvedUrl("control.py").toString().replace(/^file:\/\//, ""))
  property var languages: []
  property var rawTimezones: []
  readonly property var timezones: rawTimezones.map(zone => Object.assign({}, zone, {label: Localization.timeZoneName(zone.id), search: Localization.timeZoneName(zone.id) + " " + zone.id}))
  property var selectedLanguages: []
  property var languageNames: []
  property string timezone: ""
  readonly property string timezoneLabel: timezone ? Localization.timeZoneName(timezone) : ""
  property string errorCode: ""
  property var errorParameters: []
  readonly property string error: errorCode ? errorParameters.reduce((text, parameter) => text.includes("%1") ? text.arg(parameter) : text, qsTrId(errorCode)) : ""
  property var mouse: ({speed: 0.5, scroll: 1, acceleration: true})
  readonly property bool busy: action.running
  readonly property bool active: Settings.State.opened && ["system", "mouse", "keyboard", "timezone"].indexOf(Settings.State.page) >= 0
  onActiveChanged: if (active) { errorCode = ""; query.running = true; }
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
    onTriggered: if (root.busy) restart(); else root.apply(["mouse", root.mouse.speed, root.mouse.scroll, root.mouse.acceleration].map(String))
  }
  function accept(text) {
    try {
      const result = JSON.parse(text);
      if (result.error) { errorCode = result.error; errorParameters = result.errorParameters || []; return; }
      if (result.languages) languages = result.languages;
      if (result.timezones) rawTimezones = result.timezones;
      if (timezone && timezone !== result.timezone) Date.timeZoneUpdated();
      selectedLanguages = result.selectedLanguages;
      languageNames = result.languageNames;
      timezone = result.timezone;
      if (!mouseCommit.running) mouse = result.mouse;
      errorCode = "";
    } catch (e) { errorCode = "pond.could_not_read_system_settings"; }
  }
  function apply(args) {
    if (busy) return;
    errorCode = "";
    action.command = ["python3", root.helper].concat(args);
    action.running = true;
  }
  function toggleLanguage(id) { apply(["keyboard", id]); }
  function setTimezone(id) { if (id !== timezone) apply(["timezone", id]); }
  function setMouse(key, value) { mouse = Object.assign({}, mouse, {[key]: value}); mouseCommit.restart(); }
}
