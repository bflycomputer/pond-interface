import QtQuick
import Pond.Daylight

Rectangle {
  id: root
  property bool custom: false
  property bool dimmed: false
  property url imageSource: ""
  property alias now: sky.now
  property alias live: sky.live
  color: "#0b101c"
  layer.enabled: root.dimmed
  layer.format: ShaderEffectSource.RGBA16F

  Sky {
    id: sky
    anchors.fill: parent
    visible: !root.custom
  }
  Image {
    objectName: "wallpaperImage"
    anchors.fill: parent
    source: root.custom ? root.imageSource : ""
    fillMode: Image.PreserveAspectCrop
    asynchronous: true
  }
  Rectangle {
    visible: root.dimmed
    width: parent.width * 788 / 1728
    height: parent.height
    gradient: Gradient {
      orientation: Gradient.Horizontal
      GradientStop { position: 0; color: Qt.rgba(0, 0, 0, 0.4) }
      GradientStop { position: 1; color: Qt.rgba(0, 0, 0, 0) }
    }
  }
}
