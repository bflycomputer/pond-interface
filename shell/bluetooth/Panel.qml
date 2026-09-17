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
    function onPromptChanged() { Qt.callLater(root.syncPage); }
    function onActionFinished(path, action, success) {
      if (!root.opened) return;
      if (success && (action === "pair" || action === "connect") && path === root.nearbyConnection)
        root.connectionComplete = true;
      if (success && action === "forget" && root.currentPage === "details"
          && root.currentSelection.path === path) root.pop(false);
    }
  }
  onOpenedChanged: Qt.callLater(syncPage)
  onConnectionCompleteChanged: Qt.callLater(syncPage)
  onCurrentPageChanged: Qt.callLater(syncPage)
  onTransitionRunningChanged: if (!transitionRunning) Qt.callLater(syncPage)

  function syncPage() {
    if (!opened || transitionRunning) return;
    if (service.prompt.kind && currentPage !== "pair") {
      push("pair", null);
    } else if (!service.prompt.kind && currentPage === "pair") {
      pop(false);
    } else if (connectionComplete) {
      if (currentPage === "details" || currentPage === "nearby") pop(false);
      else { connectionComplete = false; nearbyConnection = ""; }
    }
  }
  Component { id: drawerComponent; Devices {} }
  Component { id: nearbyComponent; Nearby {} }
  Component { id: detailsComponent; Details {} }
  Component { id: pairingComponent; Pairing {} }
}
