import QtQuick
import QtQuick.Effects
import "." as Wallpaper

Item {
  id: root
  required property Wallpaper.Window wallpaper
  required property real fadeWidth
  clip: true
  layer.enabled: true
  layer.effect: MultiEffect {
    maskEnabled: true
    maskSource: fadeMask
    maskThresholdMin: 0.5
    maskSpreadAtMin: 1
  }
  Rectangle {
    id: fadeMask
    width: root.width
    height: 1
    visible: false
    layer.enabled: true
    gradient: Gradient {
      orientation: Gradient.Horizontal
      GradientStop { position: 1 - root.fadeWidth / root.width; color: "white" }
      GradientStop { position: 1; color: "transparent" }
    }
  }

  // Use the desktop's full dimensions and clock so the cropped strip lines up.
  Content {
    width: root.wallpaper.width
    height: root.wallpaper.height
    custom: root.wallpaper.custom
    imageSource: root.wallpaper.imageSource
    live: false
    now: root.wallpaper.now
    // The two surfaces can round to different physical widths at fractional scale.
    transform: Scale {
      xScale: root.Window.width > 0 && root.wallpaper.width > 0
          ? (Math.round(root.wallpaper.width * root.wallpaper.devicePixelRatio) / root.wallpaper.width)
            / (Math.round(root.Window.width * root.wallpaper.devicePixelRatio) / root.Window.width) : 1
    }
  }
}
