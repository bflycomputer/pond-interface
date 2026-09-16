pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects

// Draw only the shadow so translucent cards never reveal a solid backing rectangle.
Item {
  id: root

  property real cornerRadius: 0
  property var shadows: []

  Repeater {
    model: root.shadows

    delegate: RectangularShadow {
      required property var modelData

      anchors.fill: parent
      offset: Qt.vector2d(modelData.x, modelData.y)
      radius: root.cornerRadius
      blur: modelData.blur
      spread: 0
      color: Qt.rgba(0, 0, 0, modelData.alpha)
      antialiasing: true
      cached: false
    }
  }
}
