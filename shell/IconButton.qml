import QtQuick

Item {
  id: root
  property url iconSource
  property real iconWidth: 14
  property real iconHeight: 14
  property real restingOpacity: 0.6
  property string accessibleName: ""
  readonly property bool hovered: pointer.containsMouse
  property real glyphOpacity: hovered ? 1 : restingOpacity
  signal clicked

  implicitWidth: 24
  implicitHeight: 24
  Behavior on glyphOpacity { HoverAnimation {} }

  Image {
    anchors.centerIn: parent
    width: root.iconWidth
    height: root.iconHeight
    source: root.iconSource
    sourceSize: Qt.size(Math.ceil(width * 2), Math.ceil(height * 2))
    fillMode: Image.PreserveAspectFit
    smooth: true
    antialiasing: true
    opacity: root.glyphOpacity
  }

  MouseArea {
    id: pointer
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: root.clicked()
  }
}
