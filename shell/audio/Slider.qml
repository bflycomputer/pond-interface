import QtQuick
import ".."

Item {
  id: root

  property real value: 0
  property bool persistentHandle: false
  property bool showInlineValue: true
  property bool interactive: true
  property real dragValue: value
  signal moved(real value)

  readonly property real visualValue: pointer.pressed
      ? dragValue : Math.max(0, Math.min(1, value))
  readonly property real handleCenterX: 1
      + visualValue * Math.max(0, width - 2)
  readonly property bool hovered: pointer.containsMouse
  readonly property bool pressed: pointer.pressed
  readonly property bool showHandle: persistentHandle || hovered
  readonly property bool handleHovered: showHandle && hovered
      && Math.abs(pointer.mouseX - handleCenterX) <= 13
      && pointer.mouseY >= 3 && pointer.mouseY <= 31
  readonly property real handleSize: pressed ? 20
      : handleHovered || persistentHandle ? 26 : 24
  readonly property real handleTop: pressed ? 8
      : handleSize >= 26 ? 5 : 6

  implicitHeight: 32
  clip: false

  onValueChanged: {
    if (!pointer.pressed)
      dragValue = Math.max(0, Math.min(1, value));
  }

  Rectangle {
    x: 0
    y: 12
    width: parent.width
    height: 12
    radius: 6
    color: PanelStyle.border
  }

  Rectangle {
    x: 1
    y: 13
    width: Math.max(0, root.handleCenterX - 1)
    height: 10
    radius: 5
    color: PanelStyle.sliderFill
  }

  Rectangle {
    id: handle
    visible: root.showHandle
    x: root.handleCenterX - width / 2
    y: root.handleTop
    width: root.handleSize
    height: root.handleSize
    radius: width / 2
    color: root.pressed ? PanelStyle.accent : PanelStyle.sliderFill
    border.width: 1
    border.color: root.handleHovered && !root.pressed
        ? PanelStyle.accent : PanelStyle.border
    antialiasing: true

    Behavior on width {
      NumberAnimation {
        duration: PanelStyle.controlDuration
        easing.type: Easing.OutCubic
      }
    }
    Behavior on height {
      NumberAnimation {
        duration: PanelStyle.controlDuration
        easing.type: Easing.OutCubic
      }
    }

    Text {
      anchors.centerIn: parent
      visible: root.showInlineValue && !root.handleHovered && !root.pressed
      text: Math.round(root.visualValue * 100)
      color: PanelStyle.surface
      font.family: Theme.fontFamily
      font.weight: Font.Medium
      font.pixelSize: 13
      horizontalAlignment: Text.AlignHCenter
      verticalAlignment: Text.AlignVCenter
    }
  }

  Item {
    id: valueBubble
    z: 3
    x: root.handleCenterX - 13
    y: -19
    width: 26
    height: 22
    visible: opacity > 0.001
    opacity: root.showHandle && (root.handleHovered || root.pressed) ? 1 : 0

    Behavior on opacity {
      NumberAnimation {
        duration: PanelStyle.controlDuration
        easing.type: Easing.OutCubic
      }
    }

    Shadow {
      anchors.fill: parent
      cornerRadius: 4
      shadows: PanelStyle.controlShadows
    }

    Rectangle {
      anchors.fill: parent
      radius: 4
      color: PanelStyle.sliderBubble

      Text {
        anchors.centerIn: parent
        text: Math.round(root.visualValue * 100)
        color: "black"
        font.family: Theme.fontFamily
        font.weight: Font.Medium
        font.pixelSize: 13
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
      }
    }
  }

  MouseArea {
    id: pointer
    anchors.fill: parent
    enabled: root.interactive
    hoverEnabled: true
    preventStealing: true
    cursorShape: pressed ? Qt.ClosedHandCursor
        : root.handleHovered ? Qt.OpenHandCursor : Qt.PointingHandCursor

    onPressed: mouse => root.updateFromPosition(mouse.x)
    onPositionChanged: mouse => {
      if (pressed)
        root.updateFromPosition(mouse.x);
    }
  }

  function updateFromPosition(positionX) {
    const next = Math.max(0, Math.min(1,
        (positionX - 1) / Math.max(1, width - 2)));
    dragValue = next;
    moved(next);
  }
}
