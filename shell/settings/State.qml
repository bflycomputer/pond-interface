pragma Singleton

import QtQuick
import "." as Settings
import "../bluetooth" as Bluetooth
import ".." as Shell
import Quickshell

Singleton {
  id: root

  property bool opened: false
  property string page: ""
  property string outputName: ""
  signal opening
  property string pendingSessionAction: ""

  readonly property var sessionActions: [
    "lock", "suspend", "reboot", "shutdown"
  ]

  Timer {
    id: sessionActionDelay
    interval: Settings.Style.closeDuration
    onTriggered: {
      const action = root.pendingSessionAction;
      root.pendingSessionAction = "";
      if (action === "")
        return;
      Quickshell.execDetached([
        "python3", Quickshell.shellDir + "/settings/session.py", action
      ]);
    }
  }

  function open(requestedOutputName) {
    sessionActionDelay.stop();
    pendingSessionAction = "";
    outputName = requestedOutputName || focusedOutputName();
    page = "";
    opening();
    opened = true;
  }

  function close() {
    opened = false;
  }

  function openPage(name) {
    if (["appearance", "information", "display", "arrange"].indexOf(name) < 0) return;
    page = name;
  }

  function back() { page = page === "arrange" ? "display" : page === "display" ? "appearance" : ""; }

  function toggle(requestedOutputName) {
    const targetOutput = requestedOutputName || focusedOutputName();
    if (opened && outputName === targetOutput)
      close();
    else
      open(targetOutput);
  }

  function requestSessionAction(action) {
    if (sessionActions.indexOf(action) < 0)
      return;
    pendingSessionAction = action;
    opened = false;
    sessionActionDelay.restart();
  }

  function openBluetooth() {
    const targetOutput = outputName || focusedOutputName();
    close();
    Bluetooth.State.requestPanel("open", targetOutput);
  }

  function focusedOutputName() {
    if (Shell.NiriMsg.focusedOutputName !== "")
      return Shell.NiriMsg.focusedOutputName;
    return Quickshell.screens.length ? Quickshell.screens[0].name : "";
  }
}
