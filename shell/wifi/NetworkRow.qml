import QtQuick
import ".."

Item {
  id: root
  property var network: ({})
  property bool interactive: true
  readonly property bool canDisconnect: !!network.connected && !network.wired
  signal rowClicked
  signal detailsRequested
  signal disconnectClicked
  implicitWidth: PanelStyle.rowWidth
  implicitHeight: PanelStyle.rowHeight

  Rectangle {
    anchors.fill: parent
    radius: PanelStyle.rowRadius
    color: hover.hovered ? PanelStyle.rowHover : "transparent"
  }
  MouseArea {
    anchors.fill: parent
    enabled: root.interactive
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    cursorShape: Qt.PointingHandCursor
    onClicked: mouse => {
      if (mouse.button === Qt.RightButton)
        root.detailsRequested();
      else
        root.rowClicked();
    }
  }
  SignalIcon {
    visible: !root.network.wired
    x: 12; y: 12; width: 20; height: 20
    bars: Number(root.network.bars || 1)
  }
  Image {
    visible: !!root.network.wired
    x: 12; y: 12; width: 20; height: 20
    source: Qt.resolvedUrl("../assets/wifi/ethernet.svg")
    sourceSize: Qt.size(40, 40)
    fillMode: Image.PreserveAspectFit
  }
  Text {
    x: 40
    anchors.verticalCenter: parent.verticalCenter
    width: (root.canDisconnect ? 202 : 264) - x
    elide: Text.ElideRight
    text: String(root.network.wired ? root.network.name : root.network.ssid || "")
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
    visible: root.canDisconnect
    x: 208
    y: 2
    width: 90
    height: 40
    radius: 10
    color: disconnectHover.hovered ? PanelStyle.controlHover : "transparent"

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
