pragma ComponentBehavior: Bound
import QtQuick
import "." as Bluetooth
import ".." as Shell
Shell.CardStack {
  id: root
  property var service: Bluetooth.State
  property string nearbyConnection: ""
  property bool connectionComplete: false
  readonly property bool searchActive: opened && (currentPage === "nearby" || currentPage === "pair")
  pageComponents: ({drawer: drawerComponent, nearby: nearbyComponent,
                    details: detailsComponent, pair: pairingComponent})
  onSearchActiveChanged: service.setDiscoveryConsumer(root, searchActive)
  onPanelOpened: { service.panelOpen = true; service.errorText = ""; nearbyConnection = ""; connectionComplete = false; }
  onPanelClosed: { service.panelOpen = false; service.cancelPairing(); nearbyConnection = ""; connectionComplete = false; }
  onPagePopping: page => {
    if (page === "pair" || page === "nearby") service.cancelPairing();
  }
  Component.onDestruction: service.setDiscoveryConsumer(root, false)
  function openNearby() { if (service.enabled) push("nearby", null); }
  function openDetails(device) { push("details", {path: device.path}); }
  function connectNearby(device) {
    if (!device || service.isBusy(device.path)) return;
    nearbyConnection = device.path;
    service.activate(device);
  }
  Connections {
    target: root.service
    function onActionFinished(path, action, success) {
      if (!root.opened) return;
      if (success && (action === "pair" || action === "connect") && path === root.nearbyConnection)
        root.connectionComplete = true;
      if (success && action === "forget" && root.currentPage === "details"
          && root.currentSelection.path === path) root.pop(false);
    }
  }
  // Serialize prompt/success navigation with the existing stack animation.
  Timer {
    interval: 50; repeat: true; running: root.opened
    onTriggered: {
      if (root.transitionRunning) return;
      if (root.service.prompt.kind && root.currentPage !== "pair") {
        root.push("pair", null);
      } else if (!root.service.prompt.kind && root.currentPage === "pair") {
        root.pop(false);
      } else if (root.connectionComplete) {
        if (root.currentPage === "details" || root.currentPage === "nearby") root.pop(false);
        else { root.connectionComplete = false; root.nearbyConnection = ""; }
      }
    }
  }
  Component { id: drawerComponent; Devices {} }
  Component { id: nearbyComponent; Nearby {} }
  Component { id: detailsComponent; Details {} }
  Component { id: pairingComponent; Pairing {} }
}
