import QtQuick
import "." as Wifi
import ".."

CardStack {
  id: root
  property bool returningToNetworks: false
  property var reconnectingNetwork: null
  pageComponents: ({drawer: drawerComponent, join: joinComponent, add: addComponent,
                    details: detailsComponent, status: statusComponent})
  onOpenedChanged: {
    closeDelay.stop();
    returningToNetworks = false;
    reconnectingNetwork = null;
    Wifi.State.panelOpen = opened;
  }
  onTransitionRunningChanged: if (!transitionRunning) Qt.callLater(syncPage)

  function syncPage() {
    if (!opened || transitionRunning || !returningToNetworks)
      return;
    if (currentPage !== "drawer") {
      pop(false);
      return;
    }
    returningToNetworks = false;
    if (reconnectingNetwork)
      push("join", reconnectingNetwork);
    reconnectingNetwork = null;
  }

  function showStatus() {
    if (currentPage !== "status")
      push("status", null);
  }
  function connectNetwork(ssid, password, hidden, securityMode) {
    closeDelay.stop();
    reconnectingNetwork = !password && !securityMode
        && Wifi.State.networks.find(n => n.ssid === ssid && n.known && n.locked);
    Wifi.State.connectNetwork(ssid, password, hidden, securityMode);
    showStatus();
  }

  Connections {
    target: Wifi.State
    function onActionFinished(kind, success, message) {
      if (!root.opened || kind === "toggle")
        return;
      if (success)
        root.reconnectingNetwork = null;
      if (success && kind !== "disconnect") {
        closeDelay.restart();
      } else if (success || (kind === "connect" && root.reconnectingNetwork)) {
        root.returningToNetworks = true;
        Qt.callLater(root.syncPage);
      } else if (root.currentPage !== "status") {
        root.showStatus();
      }
    }
  }

  Timer {
    id: closeDelay
    interval: 420
    onTriggered: root.closeAll()
  }
  Component { id: drawerComponent; Networks {} }
  Component { id: joinComponent; Join {} }
  Component { id: addComponent; AddNetwork {} }
  Component { id: detailsComponent; Details {} }
  Component { id: statusComponent; Connection {} }
}
