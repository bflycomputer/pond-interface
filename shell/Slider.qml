import QtQuick
import QtQuick.Templates as T

// The one slider used across the shell: a thin rounded track with an optional
// knob, end icons, trailing value and tick marks underneath.
T.Slider {
  id: root

  property real externalValue: 0
  property bool muted: false
  property bool interactive: true
  // Indicators (keyboard feedback) hide the knob and draw the fill edge to edge.
  property bool showHandle: true
  property bool showValueBubble: true
  property int ticks: 0
  property real tickOpacity: 0.25
  property url lowIcon: ""
  property url highIcon: ""
  property real lowIconSize: 12
  property real highIconSize: 16
  property string trailingText: ""
  property color trailingColor: "white"
  property string valueText: Math.round(visualPosition * 100)
  property color trackColor: PanelStyle.border
  // Scrolling steps the value. Off by default: a slider inside a scrolling
  // page must not catch the wheel, and the scrolling-sensitivity slider would
  // change the very speed it is being scrolled with.
  property bool wheelSteps: false
  signal dragStarted
  signal dragFinished
  onPressedChanged: pressed ? dragStarted() : dragFinished()

  from: 0; to: 1
  enabled: interactive
  hoverEnabled: true
  focusPolicy: Qt.NoFocus
  handle: Item { width: 0; height: 0 }
  // Device updates resume driving the handle after the drag ends.
  Binding on value { value: root.externalValue; when: !root.pressed; restoreMode: Binding.RestoreNone }

  readonly property bool active: hovered || pressed || visualFocus
  readonly property real leadingWidth: lowIcon.toString() || muted ? 16 + 8 : 0
  readonly property real trailingWidth: trailingText ? 8 + 26 : highIcon.toString() ? 8 + 16 : 0
  readonly property real knobSize: !showHandle ? 0 : pressed ? 14 : active ? 18 : 16
  // The knob stays inside the track, so its resting radius pads both ends.
  readonly property real handleInset: showHandle ? 8 : 0
  leftPadding: leadingWidth + handleInset
  rightPadding: trailingWidth + handleInset
  readonly property real trackX: leadingWidth
  readonly property real trackWidth: width - leadingWidth - trailingWidth
  readonly property real trackCenterY: ticks > 1 ? 12 : height / 2
  readonly property real trackHeight: active && interactive ? 8 : 6
  readonly property real handleCenterX: leftPadding + visualPosition * availableWidth

  implicitWidth: 200
  implicitHeight: 32
  clip: false

  Image {
    id: lowGlyph
    x: (16 - width) / 2
    y: root.trackCenterY - height / 2
    visible: root.leadingWidth > 0
    width: root.muted ? 16 : root.lowIconSize
    height: width
    source: root.muted ? Qt.resolvedUrl("assets/volume-mute.svg") : root.lowIcon
    sourceSize: Qt.size(32, 32)
    fillMode: Image.PreserveAspectFit
    opacity: root.muted ? 0.9 : 0.6
  }

  Rectangle {
    id: track
    x: root.trackX
    y: root.trackCenterY - height / 2
    width: root.trackWidth
    height: root.trackHeight
    radius: height / 2
    color: root.trackColor
    Behavior on height {
      NumberAnimation { duration: PanelStyle.controlDuration; easing.type: Easing.OutCubic }
    }

    Rectangle {
      width: Math.max(root.showHandle ? 0 : parent.height, root.handleCenterX - root.trackX)
      height: parent.height
      radius: parent.radius
      visible: root.showHandle || root.visualPosition > 0
      color: PanelStyle.sliderFill
      opacity: root.muted ? 0.25 : 1
    }
  }

  Repeater {
    model: root.ticks > 1 ? root.ticks : 0
    Rectangle {
      required property int index
      x: root.leftPadding + index / (root.ticks - 1) * root.availableWidth - 1
      y: root.trackCenterY + 8
      width: 2; height: 2; radius: 1
      color: "white"
      opacity: root.tickOpacity
      Behavior on opacity { NumberAnimation { duration: PanelStyle.controlDuration } }
    }
  }

  Image {
    x: root.width - 16 + (16 - width) / 2
    y: root.trackCenterY - height / 2
    visible: !root.trailingText && root.highIcon.toString() !== ""
    width: root.highIconSize
    height: width
    source: root.highIcon
    sourceSize: Qt.size(32, 32)
    fillMode: Image.PreserveAspectFit
    opacity: 0.6
  }

  Text {
    x: root.width - width
    width: 26
    y: root.trackCenterY - height / 2
    visible: root.trailingText !== ""
    text: root.trailingText
    color: root.trailingColor
    opacity: 0.8
    Behavior on color { ColorAnimation { duration: PanelStyle.controlDuration } }
    horizontalAlignment: Text.AlignRight
    font.family: Theme.fontFamily
    font.weight: Font.Medium
    font.pixelSize: 13
    font.features: { "tnum": 1 }
  }

  Rectangle {
    id: knob
    visible: root.showHandle
    x: root.handleCenterX - width / 2
    y: root.trackCenterY - height / 2
    width: root.knobSize
    height: width
    radius: width / 2
    color: root.pressed ? PanelStyle.accent
        : root.muted ? PanelStyle.surface : PanelStyle.sliderFill
    border.width: root.visualFocus ? 2 : 1
    border.color: root.visualFocus || root.hovered && !root.pressed ? PanelStyle.accent
        : root.muted ? Qt.rgba(1, 1, 1, 0.5) : PanelStyle.border
    antialiasing: true
    Behavior on width {
      NumberAnimation { duration: PanelStyle.controlDuration; easing.type: Easing.OutCubic }
    }
    Behavior on color { ColorAnimation { duration: PanelStyle.controlDuration } }
  }

  Item {
    id: valueBubble
    z: 3
    width: Math.max(26, bubbleText.implicitWidth + 10)
    height: 22
    x: root.handleCenterX - width / 2
    y: root.trackCenterY - 13 - height
    visible: opacity > 0.001
    opacity: root.showValueBubble && root.showHandle && root.interactive && root.active ? 1 : 0

    Behavior on opacity {
      NumberAnimation { duration: PanelStyle.controlDuration; easing.type: Easing.OutCubic }
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
        id: bubbleText
        anchors.centerIn: parent
        text: root.valueText
        color: "black"
        font.family: Theme.fontFamily
        font.weight: Font.Medium
        font.pixelSize: 13
        font.features: { "tnum": 1 }
      }
    }
  }

  // Wheel notches and arrow keys move in the same steps as the volume and
  // brightness keys, snapping to the grid; Alt makes them fine.
  function stepBy(direction, fine) {
    const next = root.from + PanelStyle.stepLevel(root.position, direction, fine) * (root.to - root.from);
    if (next === root.value) return;
    root.value = next;
    root.moved();
  }
  LevelWheel {
    enabled: root.interactive && root.wheelSteps
    onStepped: (direction, fine) => root.stepBy(direction, fine)
  }
  Keys.onPressed: event => {
    const direction = event.key === Qt.Key_Right || event.key === Qt.Key_Up ? 1
        : event.key === Qt.Key_Left || event.key === Qt.Key_Down ? -1 : 0;
    if (direction === 0 || !root.interactive) return;
    root.stepBy(direction, (event.modifiers & Qt.AltModifier) !== 0);
    event.accepted = true;
  }

  HoverHandler {
    enabled: root.hoverEnabled
    cursorShape: root.pressed ? Qt.ClosedHandCursor : Qt.PointingHandCursor
  }
}
