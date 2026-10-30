pragma ComponentBehavior: Bound
import QtQuick
import Quickshell.Widgets
import "../information" as Information
import ".." as Settings
import "../.." as Shell

Item {
  id: root
  property bool active: true
  property string mode: "keyboard"
  readonly property bool live: active && visible

  readonly property color accent: Shell.PanelStyle.accent
  readonly property color outline: "#4a4a4a"

  readonly property real columnStep: 313
  readonly property real rowStep: 206
  property real panX: 0
  property real panY: 0

  property real superFill: 0
  property color shiftOutline: outline
  property real shiftFill: 0
  property real wheelFill: 0
  property real wheelY: 0
  readonly property real wheelCenter: 10 + 16 * wheelY

  property real fingersX: 64
  property real fingersY: 42
  property real fingersFill: 0
  property real fingersOpacity: 1

  property real trailOpacity: 0
  property real trailDir: 1
  property real trailTail: 0
  property bool trailVertical: false
  readonly property real wheelHead: trailDir > 0 ? Math.max(trailTail, wheelCenter - 5) : Math.min(trailTail, wheelCenter + 5)
  readonly property real swipeLead: trailVertical
      ? (trailDir < 0 ? fingersY + 28 : fingersY - 10)
      : (trailDir < 0 ? fingersX + 54 : fingersX - 10)
  readonly property real swipeHead: trailDir < 0 ? Math.min(trailTail, swipeLead) : Math.max(trailTail, swipeLead)

  implicitWidth: 440
  implicitHeight: 420

  function resetKeyboard() {
    panX = 0; panY = 0; trailOpacity = 0;
    shiftOutline = outline; superFill = 0; shiftFill = 0; wheelFill = 0; wheelY = 0;
  }

  function resetTrackpad() {
    panX = 0; panY = 0; trailOpacity = 0;
    fingersX = 64; fingersY = 42; fingersFill = 0; fingersOpacity = 1;
  }

  function startTrail(move, to) {
    const from = root[move];
    trailDir = to < from ? -1 : 1;
    trailVertical = move !== "fingersX";
    trailTail = move === "wheelY" ? wheelCenter - 6 * trailDir
        : trailDir < 0 ? from + (trailVertical ? 18 : 44) : from;
    trailOpacity = 1;
  }

  function select(next) {
    if (next === mode) return;
    if (next === "trackpad") { fingersX = 64; fingersY = 42; fingersOpacity = 1; }
    switchMotion.restart();
    mode = next;
  }

  component MiniWindow: Rectangle {
    id: miniWindow
    height: 200
    radius: 8
    color: "#303030"
    Repeater {
      model: 3
      Rectangle {
        required property int index
        x: miniWindow.width - 14 - 12 * index; y: 6
        width: 8; height: 8; radius: 4
        color: "transparent"
        border.width: 1; border.color: Qt.rgba(1, 1, 1, 0.2)
      }
    }
    Rectangle { x: 6; y: 20; width: miniWindow.width - 12; height: 1; color: Qt.rgba(1, 1, 1, 0.2) }
  }

  component Trail: Rectangle {
    id: trail
    property bool vertical: true
    property real tail: 0
    property real head: 0
    property real cross: 0
    property real thickness: 1
    property color tailColor: "transparent"
    property color headColor: "white"
    readonly property bool reversed: head < tail
    readonly property real length: Math.abs(head - tail)
    x: vertical ? Math.round(cross - thickness / 2) : Math.min(tail, head)
    y: vertical ? Math.min(tail, head) : Math.round(cross - thickness / 2)
    width: vertical ? thickness : length
    height: vertical ? length : thickness
    radius: thickness / 2
    visible: opacity > 0 && length > 0
    gradient: Gradient {
      orientation: trail.vertical ? Gradient.Vertical : Gradient.Horizontal
      GradientStop { position: 0; color: trail.reversed ? trail.headColor : trail.tailColor }
      GradientStop { position: 1; color: trail.reversed ? trail.tailColor : trail.headColor }
    }
  }

  component Gesture: SequentialAnimation {
    id: gesture
    property Item host
    property string fills
    property string move
    property real moveTo
    property string pan
    property real panTo
    readonly property bool keyboard: move === "wheelY"
    NumberAnimation { target: gesture.host; properties: gesture.fills; to: 1; duration: gesture.keyboard ? 160 : 220; easing.type: Easing.OutCubic }
    PauseAnimation { duration: gesture.keyboard ? 140 : 160 }
    ScriptAction { script: gesture.host.startTrail(gesture.move, gesture.moveTo) }
    ParallelAnimation {
      NumberAnimation { target: gesture.host; property: gesture.move; to: gesture.moveTo; duration: 720; easing.type: Easing.InOutCubic }
      NumberAnimation { target: gesture.host; property: gesture.pan; to: gesture.panTo; duration: 720; easing.type: Easing.InOutCubic }
    }
    ParallelAnimation {
      NumberAnimation { target: gesture.host; property: "trailOpacity"; to: 0; duration: 450; easing.type: Easing.OutCubic }
      NumberAnimation { target: gesture.host; properties: gesture.fills; to: 0; duration: gesture.keyboard ? 240 : 280; easing.type: Easing.OutCubic }
    }
  }

  component MoveFingers: SequentialAnimation {
    id: moveFingers
    property Item host
    property real toX
    property real toY
    NumberAnimation { target: moveFingers.host; property: "fingersOpacity"; to: 0; duration: 200; easing.type: Easing.InCubic }
    ScriptAction { script: { moveFingers.host.fingersX = moveFingers.toX; moveFingers.host.fingersY = moveFingers.toY; } }
    NumberAnimation { target: moveFingers.host; property: "fingersOpacity"; to: 1; duration: 280; easing.type: Easing.OutCubic }
  }

  component Fade: Behavior {
    id: fade
    SequentialAnimation {
      PauseAnimation { duration: fade.targetValue ? 100 : 0 }
      NumberAnimation { duration: fade.targetValue ? 280 : 150; easing.type: Easing.OutCubic }
    }
  }

  SequentialAnimation {
    id: keyboardLoop
    running: root.live && root.mode === "keyboard" && !switchMotion.running
    loops: Animation.Infinite
    ScriptAction { script: root.resetKeyboard() }
    PauseAnimation { duration: 300 }
    Gesture { host: root; fills: "superFill,wheelFill"; move: "wheelY"; moveTo: 1; pan: "panY"; panTo: -root.rowStep }
    PauseAnimation { duration: 450 }
    Gesture { host: root; fills: "superFill,wheelFill"; move: "wheelY"; moveTo: 0; pan: "panY"; panTo: 0 }
    PauseAnimation { duration: 150 }
    ColorAnimation { target: root; property: "shiftOutline"; to: root.accent; duration: 280 }
    PauseAnimation { duration: 300 }
    Gesture { host: root; fills: "superFill,shiftFill,wheelFill"; move: "wheelY"; moveTo: 1; pan: "panX"; panTo: -root.columnStep }
    PauseAnimation { duration: 450 }
    Gesture { host: root; fills: "superFill,shiftFill,wheelFill"; move: "wheelY"; moveTo: 0; pan: "panX"; panTo: 0 }
    PauseAnimation { duration: 150 }
    ColorAnimation { target: root; property: "shiftOutline"; to: root.outline; duration: 280 }
  }

  SequentialAnimation {
    id: trackpadLoop
    running: root.live && root.mode === "trackpad" && !switchMotion.running
    loops: Animation.Infinite
    ScriptAction { script: root.resetTrackpad() }
    PauseAnimation { duration: 150 }
    Gesture { host: root; fills: "fingersFill"; move: "fingersX"; moveTo: 16; pan: "panX"; panTo: -root.columnStep }
    PauseAnimation { duration: 450 }
    Gesture { host: root; fills: "fingersFill"; move: "fingersX"; moveTo: 64; pan: "panX"; panTo: 0 }
    PauseAnimation { duration: 100 }
    MoveFingers { host: root; toX: 40; toY: 68 }
    PauseAnimation { duration: 150 }
    Gesture { host: root; fills: "fingersFill"; move: "fingersY"; moveTo: 16; pan: "panY"; panTo: -root.rowStep }
    PauseAnimation { duration: 450 }
    Gesture { host: root; fills: "fingersFill"; move: "fingersY"; moveTo: 68; pan: "panY"; panTo: 0 }
    PauseAnimation { duration: 100 }
    MoveFingers { host: root; toX: 64; toY: 42 }
  }

  SequentialAnimation {
    id: switchMotion
    ParallelAnimation {
      NumberAnimation { target: root; properties: "panX,panY"; to: 0; duration: 720; easing.type: Easing.InOutCubic }
      NumberAnimation { target: root; property: "trailOpacity"; to: 0; duration: 220; easing.type: Easing.OutCubic }
      NumberAnimation { target: root; properties: "superFill,shiftFill,wheelFill,fingersFill,wheelY"; to: 0; duration: 300; easing.type: Easing.OutCubic }
      ColorAnimation { target: root; property: "shiftOutline"; to: root.outline; duration: 300 }
    }
    PauseAnimation { duration: 200 }
  }

  ClippingRectangle {
    width: 440; height: 224; radius: 18.457
    color: "transparent"
    Item {
      x: root.panX; y: root.panY
      MiniWindow { x: 12; y: 12; width: 307 }
      MiniWindow { x: 325; y: 12; width: 205 }
      MiniWindow { x: 536; y: 12; width: 205 }
      MiniWindow { x: 12; y: 218; width: 240 }
      MiniWindow { x: 258; y: 218; width: 170 }
      MiniWindow { x: 434; y: 218; width: 307 }
    }
  }

  Rectangle {
    width: 440; height: 224; radius: 18.457
    color: "transparent"
    border.width: 1; border.color: root.outline
  }

  Rectangle {
    x: 110; y: 204; width: 220; height: 40; radius: 20
    color: "#1d1d1d"
    border.width: 1; border.color: root.outline
    Rectangle {
      x: root.mode === "keyboard" ? 4 : 110; y: 4
      width: 106; height: 32; radius: 16
      color: Qt.alpha(root.accent, 0.1)
    }
    Repeater {
      model: [{id: "keyboard", label: qsTrId("pond.keyboard")}, {id: "trackpad", label: qsTrId("pond.trackpad")}]
      delegate: MouseArea {
        id: tab
        required property var modelData
        required property int index
        readonly property bool selected: root.mode === modelData.id
        x: index === 0 ? 4 : 110; y: 4
        width: 106; height: 32
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.select(modelData.id)
        Rectangle {
          anchors.fill: parent; radius: 16
          color: Qt.rgba(1, 1, 1, 0.1)
          opacity: tab.containsMouse && !tab.selected ? 1 : 0
          Behavior on opacity { NumberAnimation { duration: Settings.Style.hoverDuration } }
        }
        Information.Label {
          width: parent.width; capY: 11
          horizontalAlignment: Text.AlignHCenter
          text: tab.modelData.label
          font.pixelSize: 13; font.weight: Font.Medium; font.letterSpacing: 0
          color: tab.selected ? root.accent : "white"
          opacity: tab.selected || tab.containsMouse ? 1 : 0.6
          Behavior on color { ColorAnimation { duration: 240 } }
          Behavior on opacity { NumberAnimation { duration: Settings.Style.hoverDuration } }
        }
      }
    }
  }

  Item {
    y: 274 + 8 * (1 - opacity)
    width: 440; height: 86
    opacity: root.mode === "keyboard" ? 1 : 0
    visible: opacity > 0
    Fade on opacity {}
    Repeater {
      model: [
        [0, 0, 28, "tl"], [30, 0, 20], [52, 0, 20], [75, 0, 20], [97, 0, 20], [119, 0, 20], [141, 0, 20], [163, 0, 20], [185, 0, 24, "tr"],
        [0, 22, 32], [34, 22, 20], [56, 22, 20], [78, 22, 20], [100, 22, 20], [122, 22, 20], [144, 22, 20], [166, 22, 20], [188, 22, 21],
        [0, 44, 36, "shift"], [38, 44, 20], [60, 44, 20], [82, 44, 20], [104, 44, 20], [126, 44, 20], [148, 44, 20], [170, 44, 39],
        [0, 66, 20, "bl"], [22, 66, 20, "super"], [45, 66, 20], [67, 66, 76], [145, 66, 20], [167, 66, 20], [189, 66, 20, "br"]
      ]
      delegate: Rectangle {
        required property var modelData
        readonly property string role: modelData[3] || ""
        x: 84 + modelData[0]; y: modelData[1]
        width: modelData[2]; height: 20
        topLeftRadius: role === "tl" ? 8 : 2
        topRightRadius: role === "tr" ? 8 : 2
        bottomRightRadius: role === "br" ? 8 : 2
        bottomLeftRadius: role === "bl" ? 8 : 2
        color: role === "super" ? Qt.alpha(root.accent, root.superFill) : role === "shift" ? Qt.alpha(root.accent, root.shiftFill) : "transparent"
        border.width: 1
        border.color: role === "super" ? root.accent : role === "shift" ? root.shiftOutline : root.outline
      }
    }
    Rectangle {
      x: 317; width: 40; height: 56; radius: 12
      color: "transparent"
      border.width: 1; border.color: root.outline
      Trail {
        vertical: true
        tail: root.trailTail; head: root.wheelHead; cross: 20
        thickness: 2
        tailColor: "#00776191"; headColor: root.accent
        opacity: root.trailOpacity
      }
      Rectangle {
        x: 15; y: root.wheelCenter - 5
        width: 10; height: 10; radius: 5
        color: Qt.alpha(root.accent, root.wheelFill)
        border.width: 1; border.color: root.accent
      }
    }
  }

  Rectangle {
    x: 158; y: 274 + 8 * (1 - opacity)
    width: 124; height: 102; radius: 12
    color: "transparent"
    border.width: 1; border.color: root.outline
    opacity: root.mode === "trackpad" ? 1 : 0
    visible: opacity > 0
    Fade on opacity {}
    Trail {
      vertical: root.trailVertical
      tail: root.trailTail; head: root.swipeHead
      cross: root.trailVertical ? root.fingersX + 22 : root.fingersY + 9
      thickness: 1
      tailColor: Qt.alpha(root.accent, 0); headColor: root.accent
      opacity: root.trailOpacity
    }
    Item {
      x: root.fingersX; y: root.fingersY
      width: 44; height: 18
      opacity: root.fingersOpacity
      Repeater {
        model: [[0, 6], [16, 0], [32, 6]]
        delegate: Rectangle {
          required property var modelData
          x: modelData[0]; y: modelData[1]
          width: 12; height: 12; radius: 6
          color: Qt.alpha(root.accent, root.fingersFill)
          border.width: 1; border.color: root.accent
        }
      }
    }
  }
}
