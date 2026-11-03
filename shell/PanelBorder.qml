import QtQuick
import QtQuick.Shapes

// The panel outline fades out towards the bottom edge.
Shape {
  id: root
  property real radius: PanelStyle.radius
  property color color: PanelStyle.panelBorder
  anchors.fill: parent
  opacity: 0.4
  visible: Theme.translucent
  preferredRendererType: Shape.CurveRenderer

  ShapePath {
    strokeWidth: 1
    fillColor: "transparent"
    strokeGradient: LinearGradient {
      y2: root.height
      GradientStop { position: 0; color: root.color }
      GradientStop { position: 1; color: Qt.alpha(root.color, 0) }
    }
    PathRectangle {
      x: 0.5
      y: 0.5
      width: root.width - 1
      height: root.height - 1
      radius: root.radius - 0.5
    }
  }
}
