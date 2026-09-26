import QtQuick
import Pond.Daylight

Rectangle {
  id: root
  property bool custom: false
  property url imageSource: ""
  property alias now: sky.now
  property alias live: sky.live
  color: "#0b101c"

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
}
