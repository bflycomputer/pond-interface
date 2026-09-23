import QtQuick
import QtQuick.Shapes

Item {
  id: root
  property real progress: -1
  property string status: "installing"
  // Animate only changes received from the installer, never elapsed time.
  property real displayedProgress: Math.max(0, Math.min(1, progress))
  implicitWidth: 16
  implicitHeight: 16
  Behavior on displayedProgress { NumberAnimation { duration: 100 } }

  Rectangle {
    anchors.fill: parent
    visible: root.status === "installing"
    radius: width / 2
    color: "transparent"
    border.width: 2.5
    border.color: "#33d9d9d9"
    antialiasing: true
  }
  Shape {
    anchors.fill: parent
    visible: root.status === "installing" && root.displayedProgress > 0
    preferredRendererType: Shape.CurveRenderer
    ShapePath {
      strokeColor: "#d9d9d9"
      strokeWidth: 2.5
      fillColor: "transparent"
      capStyle: ShapePath.FlatCap
      PathAngleArc {
        centerX: 8; centerY: 8
        radiusX: 6.75; radiusY: 6.75
        startAngle: -90
        sweepAngle: 360 * root.displayedProgress
      }
    }
  }
  Image {
    anchors.fill: parent
    visible: root.status === "installed"
    source: Qt.resolvedUrl("../assets/installs/check.svg")
    sourceSize: Qt.size(32, 32)
  }
  Text {
    anchors.centerIn: parent
    visible: root.status === "failed"
    text: "!"
    color: "#fa6d80"
    font.pixelSize: 16
    font.bold: true
  }
}
