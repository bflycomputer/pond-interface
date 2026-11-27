import QtQuick
import QtQuick.Templates as T

T.ScrollBar {
  id: root
  required property Flickable view
  x: parent.width - 6; y: 30
  width: 4; height: parent.height - 60
  size: view.visibleArea.heightRatio
  visible: size < 1
  contentItem: Rectangle { radius: 2; color: Qt.rgba(1, 1, 1, 0.1) }
  Binding on position { value: root.view.visibleArea.yPosition; when: !root.pressed; restoreMode: Binding.RestoreNone }
  onPositionChanged: if (pressed) view.contentY = view.originY - view.topMargin + position * view.height / size
}
