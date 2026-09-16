import QtQuick
import QtQuick.VectorImage
Item {
  id: root
  property url firstFrame
  property url secondFrame
  property bool running: false
  property bool second: false
  implicitWidth: 16; implicitHeight: 16
  onRunningChanged: second = false
  // Keep both SVG scenes as vectors so scaling never enlarges a rasterized frame.
  VectorImage {
    anchors.fill: parent
    source: root.firstFrame
    visible: !root.second
    preferredRendererType: VectorImage.CurveRenderer
  }
  VectorImage {
    anchors.fill: parent
    source: root.secondFrame
    visible: root.second
    preferredRendererType: VectorImage.CurveRenderer
  }
  Timer {
    interval: 750
    running: root.running && root.visible
    repeat: true
    onTriggered: root.second = !root.second
  }
}
