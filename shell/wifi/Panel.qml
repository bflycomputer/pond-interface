import QtQuick
import "." as Wifi
import ".."

CardStack {
  id: root
  pageComponents: ({drawer: drawerComponent, join: joinComponent, add: addComponent,
                    details: detailsComponent, status: statusComponent})
  onPanelOpened: { closeDelay.stop(); Wifi.State.panelOpen = true; }
  onPanelClosed: { closeDelay.stop(); Wifi.State.panelOpen = false; }

  function showStatus() {
    if (currentPage !== "status")
      push("status", null);
  }
  function connectNetwork(ssid, password, hidden, securityMode) {
    Wifi.State.connectNetwork(ssid, password, hidden, securityMode);
    showStatus();
  }

  Connections {
    target: Wifi.State
    function onActionFinished(kind, success, message) {
      if (!root.opened || kind === "toggle")
        return;
      if (success)
        closeDelay.restart();
      else if (root.currentPage !== "status")
        root.showStatus();
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
