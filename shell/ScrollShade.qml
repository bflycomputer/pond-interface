import QtQuick

Rectangle {
  required property Flickable view
  property int easingType: Easing.Linear
  height: 16
  visible: view.contentY > 0.5
  opacity: visible ? 1 : 0
  gradient: Gradient {
    GradientStop { position: 0; color: Qt.rgba(0, 0, 0, 0.20) }
    GradientStop { position: 1; color: "transparent" }
  }
  Behavior on opacity {
    NumberAnimation { duration: PanelStyle.controlDuration; easing.type: easingType }
  }
}
