import QtQuick
import "." as Audio
import ".."

Item {
  id: root

  property bool opened: false
  readonly property int closeAllDuration: 200

  width: 336
  height: soundCard.implicitHeight + 22
  visible: opened || closeCleanup.running
  opacity: opened ? 1 : 0
  scale: opened ? 1 : 0.9
  transformOrigin: Item.BottomLeft

  Behavior on height {
    NumberAnimation {
      duration: 350
      easing.type: Easing.Bezier
      easing.bezierCurve: [0.19, 1, 0.22, 1, 1, 1]
    }
  }

  Behavior on opacity {
    NumberAnimation {
      duration: root.opened ? PanelStyle.openDuration
                            : root.closeAllDuration
      easing.type: root.opened ? Easing.InOutCubic : Easing.Bezier
      easing.bezierCurve: [0.19, 1, 0.22, 1, 1, 1]
    }
  }

  Behavior on scale {
    NumberAnimation {
      duration: root.opened ? PanelStyle.openDuration
                            : root.closeAllDuration
      easing.type: root.opened ? Easing.InOutCubic : Easing.Bezier
      easing.bezierCurve: [0.19, 1, 0.22, 1, 1, 1]
    }
  }

  Shadow {
    anchors.fill: soundCard
    cornerRadius: PanelStyle.radius
    shadows: PanelStyle.frontShadows
  }

  Devices {
    id: soundCard
    y: 22
    width: PanelStyle.width
    height: root.height - y
    interactive: root.opened
  }

  PanelCloseButton {
    x: 296
    y: 2
    enabled: root.opened
    onClicked: root.closeAll()
  }

  Timer {
    id: closeCleanup
    interval: root.closeAllDuration
  }

  function open() {
    closeCleanup.stop();
    opened = true;
    Audio.State.refreshPorts();
  }

  function closeAll() {
    if (!opened)
      return;
    opened = false;
    closeCleanup.restart();
  }

}
