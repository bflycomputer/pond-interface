import QtQuick
import QtQuick.Templates as T

T.Slider {
  id: root

  property real externalValue: 0
  property bool showInlineValue: true
  property bool interactive: true
  signal dragStarted
  signal dragFinished
  onPressedChanged: pressed ? dragStarted() : dragFinished()

  from: 0; to: 1
  leftPadding: 1; rightPadding: 1
  enabled: interactive
  hoverEnabled: true
  focusPolicy: Qt.NoFocus
  handle: Item { width: 0; height: 0 }
  // Device updates resume driving the handle after the drag ends.
  Binding on value { value: root.externalValue; when: !root.pressed; restoreMode: Binding.RestoreNone }
  readonly property real visualValue: position
  readonly property real handleCenterX: leftPadding + visualPosition * availableWidth
  readonly property bool handleHovered: hovered
      && Math.abs(pointer.point.position.x - handleCenterX) <= 13
      && pointer.point.position.y >= 3 && pointer.point.position.y <= 31
  readonly property real handleSize: pressed ? 20 : 26
  readonly property real handleTop: pressed ? 8 : 5

  implicitHeight: 32
  clip: false

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
    opacity: root.handleHovered || root.pressed ? 1 : 0

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

  HoverHandler {
    id: pointer
    enabled: root.hoverEnabled
    cursorShape: root.pressed ? Qt.ClosedHandCursor
        : root.handleHovered ? Qt.OpenHandCursor : Qt.PointingHandCursor
  }
}
