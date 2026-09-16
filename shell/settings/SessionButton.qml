import QtQuick
import "." as Settings
import ".." as Shell

// Shared 127px session action. The label is intentionally delayed a beat
// behind the immediate color response, after the immediate hover response.
Item {
  id: root

  property url iconSource
  property real iconWidth: 32
  property real iconHeight: 32
  property bool showStatusDot: false
  property color hoverColor: "white"
  property color hoverControlColor: "#632B0F"
  property string label: ""
  property real labelWidth: 127
  property bool revealed: false
  property string accessibleName: label
  property bool labelShown: false
  signal clicked

  readonly property bool hovered: pointer.containsMouse

  implicitWidth: Settings.Style.sessionSize
  implicitHeight: Settings.Style.sessionSize
  visible: opacity > 0.001
  opacity: revealed ? 1 : 0
  scale: revealed ? 1 : 0.86
  transformOrigin: Item.Center

  onRevealedChanged: {
    if (!revealed) {
      labelDelay.stop();
      labelShown = false;
    }
  }

  Behavior on opacity {
    NumberAnimation {
      duration: root.revealed ? Settings.Style.revealDuration
                              : Settings.Style.closeDuration
      easing.type: Easing.OutCubic
    }
  }

  Behavior on scale {
    NumberAnimation {
      duration: root.revealed ? Settings.Style.revealDuration
                              : Settings.Style.closeDuration
      easing.type: Easing.OutCubic
    }
  }

  Rectangle {
    id: card
    anchors.fill: parent
    radius: Settings.Style.radius
    color: root.hovered ? root.hoverColor : Settings.Style.card
    clip: true

    Behavior on color {
      ColorAnimation {
        duration: Settings.Style.hoverDuration
        easing.type: Easing.InOutCubic
      }
    }

    Rectangle {
      width: 80
      height: width
      anchors.centerIn: parent
      radius: width / 2
      color: root.hovered ? root.hoverControlColor
                          : Settings.Style.sessionControl

      Behavior on color {
        ColorAnimation {
          duration: Settings.Style.hoverDuration
          easing.type: Easing.InOutCubic
        }
      }

      Item {
        width: 32
        height: width
        anchors.centerIn: parent

        Image {
          anchors.centerIn: parent
          width: root.iconWidth
          height: root.iconHeight
          source: root.iconSource
          sourceSize: Qt.size(Math.ceil(root.iconWidth * 2),
                              Math.ceil(root.iconHeight * 2))
          fillMode: Image.PreserveAspectFit
          smooth: true
          antialiasing: true
        }
      }
    }

    Image {
      x: 110
      y: 11
      width: 6
      height: 6
      visible: root.showStatusDot
      source: Qt.resolvedUrl("../assets/settings/power-dot.svg")
      sourceSize: Qt.size(12, 12)
    }
  }

  Text {
    x: Settings.Style.sessionSize + 16
    y: (Settings.Style.sessionSize - height) / 2
    width: root.labelWidth
    height: 36
    text: root.label
    color: root.hoverColor
    opacity: root.labelShown && root.revealed ? 0.7 : 0
    font.family: Shell.Theme.titleFontFamily
    font.weight: Font.Normal
    font.pixelSize: 32
    font.letterSpacing: -0.64
    verticalAlignment: Text.AlignVCenter

    Behavior on opacity {
      NumberAnimation {
        duration: 100
        easing.type: Easing.OutCubic
      }
    }
  }

  Timer {
    id: labelDelay
    interval: 60
    onTriggered: {
      if (root.hovered && root.revealed)
        root.labelShown = true;
    }
  }

  MouseArea {
    id: pointer
    anchors.fill: parent
    enabled: root.revealed && root.opacity > 0.9
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor

    onContainsMouseChanged: {
      if (containsMouse && root.revealed) {
        labelDelay.restart();
      } else {
        labelDelay.stop();
        root.labelShown = false;
      }
    }

    onClicked: root.clicked()
  }
}
