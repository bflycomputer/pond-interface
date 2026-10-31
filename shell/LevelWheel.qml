import QtQuick

// Scrolling over a level: each wheel notch is one key press, and Alt makes
// it a fine step.
WheelHandler {
  id: root
  property real pending: 0
  signal stepped(int direction, bool fine)
  acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
  onWheel: event => {
    // Qt reports Alt+wheel as a horizontal scroll.
    pending += event.angleDelta.y !== 0 ? event.angleDelta.y : event.angleDelta.x;
    const fine = (event.modifiers & Qt.AltModifier) !== 0;
    while (Math.abs(pending) >= 120) {
      const direction = pending > 0 ? 1 : -1;
      pending -= direction * 120;
      root.stepped(direction, fine);
    }
  }
}
