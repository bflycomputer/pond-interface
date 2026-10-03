import QtQuick
import QtQuick.Effects
import ".." as Shell

// Continuous, low-cost marquee used by the two metadata rows. Overflow always
// receives an edge fade, but movement is gated by playback so paused/stopped
// tracks remain still as requested.
Item {
  id: root

  property string text: ""
  property color textColor: Shell.Theme.sidebarV3Foreground
  property string fontFamily: Shell.Theme.fontFamily
  property int fontWeight: Font.Normal
  property real fontPixelSize: 13
  property bool playing: false
  property int startDelay: 900
  property int pixelsPerSecond: 22
  property int marqueeGap: 24
  property real offset: 0

  readonly property real textWidth: primaryText.implicitWidth
  readonly property bool overflowing: textWidth > width + 0.5
  readonly property bool shouldScroll: visible && playing && overflowing
  readonly property real cycleWidth: textWidth + marqueeGap
  readonly property real leftFadeWidth: Math.min(10, Math.max(1, width / 4))
  readonly property real leftFadeAmount: Math.max(0, Math.min(1,
      -offset / leftFadeWidth, (cycleWidth + offset) / leftFadeWidth))

  clip: true
  layer.enabled: overflowing
  layer.effect: MultiEffect {
    maskEnabled: true
    maskSource: edgeMask
    maskThresholdMin: 0.5
    maskSpreadAtMin: 1
  }

  onTextChanged: reset()
  onWidthChanged: reset()
  onShouldScrollChanged: {
    if (!shouldScroll)
      offset = 0;
  }

  SequentialAnimation {
    id: marqueeAnimation
    running: root.shouldScroll
    loops: Animation.Infinite

    PropertyAction { target: root; property: "offset"; value: 0 }
    PauseAnimation { duration: root.startDelay }
    NumberAnimation {
      target: root
      property: "offset"
      from: 0
      to: -root.cycleWidth
      duration: Math.max(3200,
          Math.round(root.cycleWidth / root.pixelsPerSecond * 1000))
      easing.type: Easing.Linear
    }
  }

  Text {
    id: primaryText
    x: root.offset
    y: 0
    height: parent.height
    text: root.text
    color: root.textColor
    font.family: root.fontFamily
    font.weight: root.fontWeight
    font.pixelSize: root.fontPixelSize
    verticalAlignment: Text.AlignVCenter
    wrapMode: Text.NoWrap
  }

  Text {
    x: root.offset + root.cycleWidth
    y: 0
    height: parent.height
    visible: root.shouldScroll
    text: root.text
    color: root.textColor
    font.family: root.fontFamily
    font.weight: root.fontWeight
    font.pixelSize: root.fontPixelSize
    verticalAlignment: Text.AlignVCenter
    wrapMode: Text.NoWrap
  }

  Rectangle {
    id: edgeMask
    width: parent.width
    height: parent.height
    visible: false
    layer.enabled: true
    gradient: Gradient {
      orientation: Gradient.Horizontal
      GradientStop { position: 0; color: Qt.rgba(1, 1, 1, 1 - root.leftFadeAmount) }
      GradientStop { position: root.leftFadeWidth / Math.max(1, root.width); color: "white" }
      GradientStop { position: 1 - Math.min(14 / Math.max(1, root.width), 1 / 3); color: "white" }
      GradientStop { position: 1; color: "transparent" }
    }
  }

  function reset() {
    marqueeAnimation.restart();
    offset = 0;
    if (!shouldScroll)
      marqueeAnimation.stop();
  }
}
