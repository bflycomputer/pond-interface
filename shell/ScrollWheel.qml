import QtQuick

WheelHandler {
  id: root
  required property Flickable view
  parent: view
  acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
  target: null
  enabled: view.interactive
  onWheel: event => {
    // Keep touchpad pixel deltas native.
    if (event.phase !== Qt.NoScrollPhase || event.angleDelta.y === 0) {
      event.accepted = false;
      return;
    }
    view.cancelFlick();
    const start = wheelMotion.running ? wheelMotion.to : view.contentY;
    // Each scroll line is 40 logical pixels, independent of card height.
    const delta = event.angleDelta.y / 120 * Qt.styleHints.wheelScrollLines * 40;
    wheelMotion.from = view.contentY;
    const minimum = view.originY - view.topMargin;
    const maximum = Math.max(minimum, view.originY + view.contentHeight - view.height + view.bottomMargin);
    wheelMotion.to = Math.max(minimum, Math.min(maximum, start - delta));
    wheelMotion.restart();
    event.accepted = true;
  }

  readonly property Connections dragConnection: Connections {
    target: root.view
    function onDraggingChanged() { if (root.view.dragging) wheelMotion.stop(); }
  }

  readonly property NumberAnimation wheelMotion: NumberAnimation {
    target: root.view
    property: "contentY"
    duration: 120
    easing.type: Easing.OutCubic
  }
}
