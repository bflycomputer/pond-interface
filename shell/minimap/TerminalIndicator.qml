pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Shapes
import "loaders" as Loaders

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

  // Loader frames are svgtoqml -c output of assets/terminal-loaders. VectorImage
  // converts its SVG at runtime, and Qt keeps that memory after the item is
  // destroyed, so every window icon that came and went leaked.
  readonly property Component frameFlowerRead: Component { Loaders.FlowerRead {} }
  readonly property Component frameFlowerUnread: Component { Loaders.FlowerUnread {} }
  readonly property Component frameFlowerWorking1: Component { Loaders.FlowerWorking1 {} }
  readonly property Component frameFlowerWorking2: Component { Loaders.FlowerWorking2 {} }
  readonly property Component frameHourglassRead: Component { Loaders.HourglassRead {} }
  readonly property Component frameHourglassUnread: Component { Loaders.HourglassUnread {} }
  readonly property Component frameHourglassWorking1: Component { Loaders.HourglassWorking1 {} }
  readonly property Component frameHourglassWorking2: Component { Loaders.HourglassWorking2 {} }
  readonly property Component frameSproutRead: Component { Loaders.SproutRead {} }
  readonly property Component frameSproutUnread: Component { Loaders.SproutUnread {} }
  readonly property Component frameSproutWorking1: Component { Loaders.SproutWorking1 {} }
  readonly property Component frameSproutWorking2: Component { Loaders.SproutWorking2 {} }
  readonly property Component frameSproutWorking3: Component { Loaders.SproutWorking3 {} }
  readonly property Component frameSproutWorking4: Component { Loaders.SproutWorking4 {} }

  Repeater {
    // Keep SVG frames loaded so animation only changes visibility.
    model: root.variant === 1 ? 0 : root.workingFrameCount + 2
    delegate: Loader {
      required property int index
      anchors.centerIn: parent
      visible: root.dotState === "working" ? index === root.animationFrame
          : index === root.workingFrameCount + (root.orange ? 0 : 1)
      // Scale the hourglass artwork from 20px to 18px.
      width: root.variant === 2 ? 36 : 40
      height: width
      sourceComponent: root["frame" + ["Square", "Hourglass", "Sprout", "Flower"][root.variant - 1]
          + (index < root.workingFrameCount ? "Working" + (index + 1)
              : index === root.workingFrameCount ? "Unread" : "Read")]
    }
  }
}
