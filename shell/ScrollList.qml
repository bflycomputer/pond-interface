import QtQuick

ListView {
  id: root
  clip: true
  boundsBehavior: Flickable.StopAtBounds

  onDraggingChanged: if (dragging) wheelMotion.stop()

  WheelHandler {
    parent: root
    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
    target: null
    enabled: root.interactive
    onWheel: event => {
      // Keep touchpad pixel deltas native.
      if (event.phase !== Qt.NoScrollPhase || event.angleDelta.y === 0) {
        event.accepted = false;
        return;
      }
      root.cancelFlick();
      const start = wheelMotion.running ? wheelMotion.to : root.contentY;
      // Each scroll line is 40 logical pixels, independent of card height.
      const delta = event.angleDelta.y / 120 * Qt.styleHints.wheelScrollLines * 40;
      wheelMotion.from = root.contentY;
      const minimum = root.originY - root.topMargin;
      const maximum = Math.max(minimum, root.originY + root.contentHeight - root.height + root.bottomMargin);
      wheelMotion.to = Math.max(minimum, Math.min(maximum, start - delta));
      wheelMotion.restart();
      event.accepted = true;
    }
  }

  NumberAnimation {
    id: wheelMotion
    target: root
    property: "contentY"
    duration: 120
    easing.type: Easing.OutCubic
  }
}
