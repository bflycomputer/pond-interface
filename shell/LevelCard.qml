import QtQuick

// A level such as volume or brightness. Interactive under the pointer, also
// when it first appeared as keyboard feedback; read-only while floating.
FeedbackCard {
  id: root
  property real value: 0
  property bool muted: false
  property url icon: ""
  property bool interactive: false
  // Alt steps reveal the tick grid and tint the value.
  property bool fine: false
  readonly property bool pressed: slider.pressed
  signal moved(real value)
  signal held(bool pressed)
  Accessible.role: interactive ? Accessible.Slider : Accessible.ProgressBar
  Accessible.name: title + " " + Math.round(value * 100) + "%"

  // Pressing past either end nudges the track toward that end.
  function bump(direction) {
    nudgeAnimation.direction = direction;
    nudgeAnimation.restart();
  }

  Slider {
    id: slider
    anchors.fill: parent
    transform: Translate { id: nudge }
    externalValue: root.value
    muted: root.muted
    lowIcon: root.icon
    lowIconSize: 14
    trailingText: root.muted ? "" : Math.round((root.interactive ? visualPosition : root.value) * 100)
    trailingColor: root.fine ? PanelStyle.accent : "white"
    ticks: 11
    tickOpacity: root.fine ? 0.35 : 0
    trackColor: Theme.daylight ? Theme.sidebarInnerOutline : PanelStyle.border
    showHandle: root.interactive
    showValueBubble: false
    interactive: root.interactive
    hoverEnabled: root.interactive
    wheelSteps: true
    onMoved: root.moved(value)
    onPressedChanged: root.held(pressed)
  }

  SequentialAnimation {
    id: nudgeAnimation
    property int direction: 1
    NumberAnimation {
      target: nudge; property: "x"
      to: 4 * nudgeAnimation.direction
      duration: 70; easing.type: Easing.OutQuad
    }
    NumberAnimation {
      target: nudge; property: "x"
      to: 0
      duration: 260; easing.type: Easing.OutBack; easing.overshoot: 3
    }
  }
}
