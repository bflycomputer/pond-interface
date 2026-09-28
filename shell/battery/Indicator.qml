import QtQuick

// Fill the battery outline continuously from 0–100%.
Item {
  id: root
  property real percentage: 0
  property bool charging: false
  readonly property real level: Math.max(0, Math.min(100, percentage)) / 100
  implicitWidth: 16; implicitHeight: 16
  Image {
    anchors.fill: parent
    source: Qt.resolvedUrl("../assets/battery/outline.svg")
    sourceSize: Qt.size(width * 2, height * 2)
  }
  Rectangle {
    x: root.width * 6 / 16
    width: root.width * 4 / 16
    height: root.height * 9 / 16 * root.level
    y: root.height * 13 / 16 - height
    color: "white"
  }
  Image {
    x: root.width * 12 / 16
    y: root.height * 3 / 16
    width: root.width * 4 / 16
    height: root.height * 8 / 16
    visible: root.charging
    source: Qt.resolvedUrl("../assets/battery/charging.svg")
    sourceSize: Qt.size(width * 2, height * 2)
    smooth: true
  }
}
