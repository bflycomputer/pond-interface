pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Shapes
import QtQuick.VectorImage

Item {
  id: root

  property string dotState: "read"
  property int loaderVariant: 1
  property int animationFrame: 0
  readonly property int variant: Math.max(1, Math.min(4, loaderVariant))
  readonly property int workingFrameCount: variant === 3 ? 4 : 2
  readonly property bool animating: visible && dotState === "working"
  readonly property bool orange: dotState === "unread" || dotState === "attention"

  width: 24
  height: 24
  Accessible.role: Accessible.Indicator
  Accessible.name: "Terminal " + variant + (dotState === "working" ? " working"
      : dotState === "attention" ? " waiting for input"
      : dotState === "unread" ? " finished, unread" : " ready, viewed")

  onAnimatingChanged: animationFrame = 0
  onLoaderVariantChanged: { animationFrame = 0; if (animating) frameTimer.restart(); }

  Timer {
    id: frameTimer
    interval: 500
    repeat: true
    running: root.animating
    onTriggered: root.animationFrame = (root.animationFrame + 1) % root.workingFrameCount
  }

  Shape {
    id: square
    anchors.centerIn: parent
    visible: root.variant === 1
    width: 14; height: 14
    preferredRendererType: Shape.CurveRenderer
    rotation: root.orange || (root.dotState === "working" && root.animationFrame === 1) ? 45 : 0
    ShapePath {
      strokeWidth: -1
      fillColor: root.dotState === "working" ? "#CBA6F7"
          : root.orange ? "#FF9F67" : "#CBE25B"
      PathRectangle { width: square.width; height: square.height; radius: 1 }
    }
  }

  Repeater {
    // Keep SVG frames loaded so animation only changes visibility.
    model: root.variant === 1 ? 0 : root.workingFrameCount + 2
    delegate: VectorImage {
      required property int index
      anchors.centerIn: parent
      visible: root.dotState === "working" ? index === root.animationFrame
          : index === root.workingFrameCount + (root.orange ? 0 : 1)
      // Scale the hourglass artwork from 20px to 18px.
      width: root.variant === 2 ? 36 : 40
      height: width
      source: "../assets/terminal-loaders/" + ["square", "hourglass", "sprout", "flower"][root.variant - 1]
          + "-" + (index < root.workingFrameCount ? "working-" + (index + 1)
              : index === root.workingFrameCount ? "unread" : "read") + ".svg"
      preferredRendererType: VectorImage.CurveRenderer
    }
  }
}
