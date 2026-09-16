import QtQuick
import ".."

Item {
  id: root

  property bool opened: false
  readonly property int closeAllDuration: 200

  width: PanelStyle.width
  height: soundCard.implicitHeight
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
    anchors.fill: parent
    cornerRadius: PanelStyle.radius
    shadows: PanelStyle.frontShadows
  }

  Devices {
    id: soundCard
    anchors.fill: parent
    interactive: root.opened
  }

  Timer {
    id: closeCleanup
    interval: root.closeAllDuration
  }

  function open() {
    closeCleanup.stop();
    opened = true;
  }

  function closeAll() {
    if (!opened)
      return;
    opened = false;
    closeCleanup.restart();
  }

}
