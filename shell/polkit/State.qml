pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Polkit
import ".." as Shell

// Polkit authentication agent for the session. Registration fails harmlessly
// if another agent (such as hyprpolkitagent) is already running.
Singleton {
  id: root

  readonly property var flow: agent.isActive ? agent.flow : null
  // Captured when a request starts so the dialog stays on one screen.
  property string outputName: ""

  // The polkit helper is socket activated, and PAM can send messages (such as
  // pam_faillock's lockout notice) before it asks for the password. Open the
  // dialog once PAM is ready so it appears with its final layout instead of
  // growing a moment later. Fall back to opening anyway after a short wait.
  property bool opened: false
  readonly property bool pamReady: flow !== null
      && (flow.isResponseRequired || !!flow.supplementaryMessage || flow.isCompleted)
  onPamReadyChanged: if (pamReady) opened = true
  onFlowChanged: if (flow === null) opened = false

  Timer {
    id: openFallback
    interval: 400
    onTriggered: if (root.flow !== null) root.opened = true
  }

  PolkitAgent {
    id: agent
    onAuthenticationRequestStarted: {
      const focused = Shell.NiriMsg.focusedOutputName;
      const screens = Quickshell.screens;
      root.outputName = screens.some(s => s.name === focused)
          ? focused : (screens[0]?.name ?? "");
      root.opened = root.pamReady;
      openFallback.restart();
    }
  }
}
