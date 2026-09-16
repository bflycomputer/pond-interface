import QtQuick
import ".."

Item {
  id: root
  property int bars: 3
  implicitWidth: 20
  implicitHeight: 20

  Image {
    anchors.centerIn: parent
    width: 17.5
    height: 12.8
    source: root.bars >= 3
        ? Qt.resolvedUrl("../assets/wifi/signal-3.svg")
        : root.bars === 2
          ? Qt.resolvedUrl("../assets/wifi/signal-2.svg")
          : Qt.resolvedUrl("../assets/wifi/signal-1.svg")
    sourceSize: Qt.size(35, 26)
    fillMode: Image.Stretch
    smooth: true
    antialiasing: true
  }
}
