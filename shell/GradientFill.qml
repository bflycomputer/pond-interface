import QtQuick

// Reduce banding by dithering a float layer into the 8-bit window.
Item {
  id: root
  // Track gradient changes here; Rectangle.gradient has no change signal.
  property Gradient fill: null
  property alias color: surface.color
  // Leave room for antialiasing around the rounded edge.
  anchors { fill: parent; margins: -1 }
  z: -1
  layer.enabled: fill !== null
  layer.smooth: true
  layer.format: ShaderEffectSource.RGBA16F
  layer.effect: ShaderEffect {
    fragmentShader: Qt.resolvedUrl("dither.frag.qsb")
  }

  Rectangle {
    id: surface
    anchors { fill: parent; margins: 1 }
    radius: root.parent.radius
    color: "transparent"
    gradient: root.fill
  }
}
