import QtQuick
import "." as Settings

Item {
  id: root

  property url iconSource
  property real iconBoxWidth: 72
  property real iconBoxHeight: 72
  property real iconWidth: iconBoxWidth
  property real iconHeight: iconBoxHeight
  property bool revealed: false
  property string accessibleName: ""
  signal clicked

  readonly property bool hovered: pointer.containsMouse

  implicitWidth: 264
  implicitHeight: 264
  visible: opacity > 0.001
  opacity: revealed ? 1 : 0
  scale: revealed ? 1 : 0.86
  transformOrigin: Item.Center

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
    anchors.fill: parent
    radius: Settings.Style.radius
    color: root.hovered ? Settings.Style.hover
                        : Settings.Style.card
    clip: true

    Behavior on color {
      ColorAnimation {
        duration: Settings.Style.hoverDuration
        easing.type: Easing.InOutCubic
      }
    }

    Item {
      width: root.iconBoxWidth
      height: root.iconBoxHeight
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

  MouseArea {
    id: pointer
    anchors.fill: parent
    enabled: root.revealed && root.opacity > 0.9
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: root.clicked()
  }
}
