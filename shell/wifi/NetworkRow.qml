import QtQuick
import ".."

Item {
  id: root
  property var network: ({})
  property bool interactive: true
  signal rowClicked
  signal disconnectClicked
  implicitWidth: PanelStyle.rowWidth
  implicitHeight: PanelStyle.rowHeight

  Rectangle {
    anchors.fill: parent
    radius: PanelStyle.rowRadius
    color: hover.hovered ? PanelStyle.hover : "transparent"
  }
  MouseArea {
    anchors.fill: parent
    enabled: root.interactive
    cursorShape: Qt.PointingHandCursor
    onClicked: root.rowClicked()
  }
  SignalIcon {
    x: 12; y: 12; width: 20; height: 20
    bars: Number(root.network.bars || 1)
  }
  Text {
    x: 40
    anchors.verticalCenter: parent.verticalCenter
    width: (root.network.connected ? 202 : 264) - x
    elide: Text.ElideRight
    text: String(root.network.ssid || "")
    color: "white"
    font.family: Theme.fontFamily
    font.weight: Font.Medium
    font.pixelSize: 13
  }
  Image {
    visible: !!root.network.locked && !root.network.connected
    x: 272
    anchors.verticalCenter: parent.verticalCenter
    width: 16
    height: 16
    source: Qt.resolvedUrl("../assets/wifi/lock.svg")
  }

  Rectangle {
    id: disconnect
    visible: !!root.network.connected
    x: 208
    y: 2
    width: 90
    height: 40
    radius: 10
    color: disconnectHover.hovered ? PanelStyle.pressed : "transparent"

    Text {
      anchors.centerIn: parent
      text: "Disconnect"
      color: "white"
      opacity: disconnectHover.hovered ? 1 : 0.8
      font.family: Theme.fontFamily
      font.weight: Font.Medium
      font.pixelSize: 13
    }
    HoverHandler {
      id: disconnectHover
      enabled: root.interactive
      cursorShape: Qt.PointingHandCursor
    }
    MouseArea {
      anchors.fill: parent
      enabled: root.interactive
      cursorShape: Qt.PointingHandCursor
      onClicked: root.disconnectClicked()
    }
  }
  HoverHandler { id: hover; enabled: root.interactive; cursorShape: Qt.PointingHandCursor }
}
