import QtQuick
import ".."
import QtQuick.Shapes

Item {
  id: root
  property bool checked: false
  signal toggled(bool checked)
  implicitWidth: 24
  implicitHeight: 24

  Rectangle {
    anchors.fill: parent
    radius: 6
    color: checkHover.hovered ? PanelStyle.pressed : PanelStyle.hover
  }

  Shape {
    anchors.centerIn: parent
    width: 20
    height: 20
    visible: root.checked
    ShapePath {
      strokeColor: PanelStyle.accent
      strokeWidth: 2
      capStyle: ShapePath.RoundCap
      joinStyle: ShapePath.RoundJoin
      fillColor: "transparent"
      startX: 4
      startY: 10
      PathLine { x: 8; y: 14 }
      PathLine { x: 16; y: 6 }
    }
  }

  HoverHandler { id: checkHover; cursorShape: Qt.PointingHandCursor }
  TapHandler { onTapped: root.toggled(!root.checked) }
}
