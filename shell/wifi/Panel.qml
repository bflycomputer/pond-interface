import QtQuick
import "." as Wifi
import ".."

CardStack {
  id: root
  property bool returningToNetworks: false
  pageComponents: ({drawer: drawerComponent, join: joinComponent, add: addComponent,
                    details: detailsComponent, status: statusComponent})
  onOpenedChanged: {
    closeDelay.stop();
    passwordErrorDelay.stop();
    returningToNetworks = false;
    Wifi.State.panelOpen = opened;
  }
  onPagePopping: passwordErrorDelay.stop()
  onTransitionRunningChanged: if (!transitionRunning) Qt.callLater(syncPage)

  function syncPage() {
    if (!opened || transitionRunning || !returningToNetworks)
      return;
    if (currentPage !== "drawer") {
      pop(false);
      return;
    }
    returningToNetworks = false;
  }

  function showStatus() {
    if (currentPage !== "status")
      push("status", null);
  }
  function connectNetwork(ssid, password, hidden, securityMode, enterprise) {
    closeDelay.stop();
    passwordErrorDelay.stop();
    Wifi.State.connectNetwork(ssid, password, hidden, securityMode, enterprise);
    showStatus();
  }

  Connections {
    target: Wifi.State
    function onActionFinished(kind, success, message) {
      if (!root.opened || kind === "toggle")
        return;
      if (success && kind !== "disconnect") {
        closeDelay.interval = kind === "connect" ? 1500 : 420;
        closeDelay.restart();
      } else if (success) {
        root.returningToNetworks = true;
        Qt.callLater(root.syncPage);
      } else {
        if (root.currentPage !== "status")
          root.showStatus();
        if (kind === "connect" && message === "Incorrect password")
          passwordErrorDelay.restart();
      }
    }
  }

  Timer {
    id: closeDelay
    interval: 420
    onTriggered: root.closeAll()
  }
  Timer {
    id: passwordErrorDelay
    interval: 1000
    onTriggered: if (root.currentPage === "status") root.pop()
  }
  Component { id: drawerComponent; Networks {} }
  Component { id: joinComponent; Join {} }
  Component { id: addComponent; AddNetwork {} }
  Component { id: detailsComponent; Details {} }
  Component { id: statusComponent; Connection {} }
}
