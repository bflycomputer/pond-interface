import QtQuick

Behavior {
  id: root
  SequentialAnimation {
    PauseAnimation { duration: root.targetValue > 0 ? 60 : 0 }
    NumberAnimation {
      duration: root.targetValue > 0 ? 160 : PanelStyle.hoverExitDuration
      easing.type: Easing.OutCubic
    }
  }
}
