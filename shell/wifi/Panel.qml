pragma ComponentBehavior: Bound

import QtQuick
import "." as Wifi
import ".."

// Keep page instances alive while they move behind the front card, preserving
// entered text and selections when the user goes back.
Item {
  id: root

  property bool opened: false
  property bool transitionRunning: false
  property string transitionOperation: ""
  property real transitionProgress: 1
  property real transitionFromHeight: 0
  property real transitionToHeight: 0
  property real transitionFromInset: 22
  property real transitionToInset: 22

  readonly property int collapseAllDuration: 200
  readonly property int depth: stackModel.count
  readonly property var currentEntry: depth > 0
      ? stackModel.get(depth - 1) : null
  readonly property string currentPage: currentEntry
      ? String(currentEntry.entryPage) : ""
  readonly property real frontHeight: depth > 0
      && layerRepeater.itemAt(depth - 1)
      ? layerRepeater.itemAt(depth - 1).naturalHeight : 0
  readonly property real frontInset: transitionRunning
      ? Theme.lerp(transitionFromInset, transitionToInset,
                   transitionProgress)
      : insetForDepth(depth)

  width: 336
  height: transitionRunning
      ? Theme.lerp(transitionFromHeight, transitionToHeight,
                   transitionProgress)
      : frontHeight + insetForDepth(depth)
  visible: opened || closeCleanup.running
  opacity: opened ? 1 : 0
  scale: opened ? 1 : 0.9
  transformOrigin: Item.BottomLeft

  Behavior on opacity {
    NumberAnimation {
      duration: root.opened ? PanelStyle.openDuration
                            : root.collapseAllDuration
      easing.type: root.opened ? Easing.InOutCubic : Easing.Bezier
      easing.bezierCurve: [0.19, 1, 0.22, 1, 1, 1]
    }
  }
  Behavior on scale {
    NumberAnimation {
      duration: root.opened ? PanelStyle.openDuration
                            : root.collapseAllDuration
      easing.type: root.opened ? Easing.InOutCubic : Easing.Bezier
      easing.bezierCurve: [0.19, 1, 0.22, 1, 1, 1]
    }
  }

  ListModel {
    id: stackModel
    dynamicRoles: true
  }

  function insetForDepth(cardDepth) {
    return cardDepth > 1 ? 32 : 22;
  }

  function openDrawer() {
    if (opened) {
      closeAll();
      return;
    }
    closeCleanup.stop();
    transitionAnimation.stop();
    transitionRunning = false;
    transitionOperation = "";
    transitionProgress = 1;
    stackModel.clear();
    stackModel.append({ entryPage: "drawer", entryNetwork: ({}) });
    opened = true;
    closeDelay.stop();
    Wifi.State.panelOpen = true;
  }

  function push(page, network) {
    if (transitionRunning)
      return;

    transitionFromInset = insetForDepth(depth);
    transitionFromHeight = frontHeight + transitionFromInset;
    transitionToInset = insetForDepth(depth + 1);
    transitionToHeight = transitionFromHeight;
    transitionOperation = "push";
    transitionProgress = 0;
    transitionRunning = true;
    stackModel.append({ entryPage: page,
                        entryNetwork: network || ({}) });
    transitionStart.restart();
  }

  function beginPush() {
    const incoming = layerRepeater.itemAt(depth - 1);
    if (!incoming || !incoming.ready || incoming.naturalHeight <= 0) {
      transitionStart.restart();
      return;
    }
    transitionToHeight = incoming.naturalHeight + transitionToInset;
    transitionAnimation.restart();
  }

  function pop() {
    if (transitionRunning)
      return;
    if (depth <= 1) {
      closeAll();
      return;
    }

    const returning = layerRepeater.itemAt(depth - 2);
    if (!returning || returning.naturalHeight <= 0)
      return;
    transitionFromInset = insetForDepth(depth);
    transitionFromHeight = frontHeight + transitionFromInset;
    transitionToInset = insetForDepth(depth - 1);
    transitionToHeight = returning.naturalHeight + transitionToInset;
    transitionOperation = "pop";
    transitionProgress = 0;
    transitionRunning = true;
    transitionAnimation.restart();
  }

  function finishTransition() {
    if (transitionOperation === "pop" && depth > 0)
      stackModel.remove(depth - 1);
    transitionOperation = "";
    transitionProgress = 1;
    transitionRunning = false;
  }

  function closeAll() {
    if ((!opened && !closeCleanup.running) || !visible)
      return;
    transitionAnimation.stop();
    transitionStart.stop();
    transitionRunning = false;
    transitionOperation = "";
    opened = false;
    closeDelay.stop();
    Wifi.State.panelOpen = false;
    closeCleanup.restart();
  }

  Timer {
    id: transitionStart
    interval: 1
    onTriggered: root.beginPush()
  }

  Timer {
    id: closeCleanup
    interval: root.collapseAllDuration
    onTriggered: {
      if (!root.opened)
        stackModel.clear();
    }
  }

  Repeater {
    id: layerRepeater
    model: stackModel

    delegate: Layer {
      id: stackLayer
      required property int index
      required property string entryPage
      required property var entryNetwork

      readonly property int relativeIndex: root.depth - 1 - index
      readonly property bool pushFront: root.transitionOperation === "push"
          && relativeIndex === 0
      readonly property bool pushBack: root.transitionOperation === "push"
          && relativeIndex === 1
      readonly property bool popFront: root.transitionOperation === "pop"
          && relativeIndex === 0
      readonly property bool popBack: root.transitionOperation === "pop"
          && relativeIndex === 1

      page: entryPage
      network: entryNetwork
      cardComponent: ({drawer: drawerComponent, join: joinComponent, add: addComponent,
                       details: detailsComponent, status: statusComponent})[entryPage]
      stackController: root
      interactive: !root.transitionRunning && relativeIndex === 0

      x: 16 * backingAmount
      y: Theme.lerp(pushBack ? root.transitionFromInset
          : popBack ? root.transitionToInset : root.frontInset, 16, backingAmount)
      width: Theme.lerp(PanelStyle.width, 284, backingAmount)
      height: Theme.lerp(naturalHeight, 90, backingAmount)
      backingAmount: pushBack ? root.transitionProgress
          : popBack ? 1 - root.transitionProgress
          : relativeIndex === 0 ? 0 : 1
      cardOpacity: popBack ? 1 : 1 - backingAmount
      opacity: pushFront ? root.transitionProgress
          : popFront ? 1
          : relativeIndex <= 1 ? 1 : 0
      scale: pushFront ? 0.92 + 0.08 * root.transitionProgress
          : popFront ? Math.max(0, 1 - 2 * root.transitionProgress) : 1
      transformOrigin: Item.Bottom
      visible: opacity > 0.001
      z: index
    }
  }

  CloseButton {
    z: 100
    x: 296
    y: root.frontInset - 20
    enabled: !root.transitionRunning
    onClicked: root.pop()
  }

  NumberAnimation {
    id: transitionAnimation
    target: root
    property: "transitionProgress"
    from: 0
    to: 1
    duration: PanelStyle.pageDuration
    easing.type: Easing.Bezier
    easing.bezierCurve: [0.19, 1, 0.22, 1, 1, 1]
    onFinished: root.finishTransition()
  }

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
