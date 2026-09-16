pragma ComponentBehavior: Bound
import QtQuick
import "." as Wifi
import ".."

DeviceList {
  id: root
  title: "Wifi"
  viewportHeight: 306
  devices: Wifi.State.enabled ? Wifi.State.networks : []
  headerControl: Component { Toggle {
    checked: Wifi.State.enabled
    enabled: root.interactive
    onToggled: checked => Wifi.State.setWifiEnabled(checked)
  } }
  deviceDelegate: Component { NetworkRow {
    required property var modelData
    width: PanelStyle.rowWidth
    network: modelData
    interactive: root.interactive
    onDisconnectClicked: Wifi.State.disconnect()
    onRowClicked: {
      if (modelData.connected)
        root.stackController.push("details", modelData);
      else if (modelData.locked)
        root.stackController.push("join", modelData);
      else
        root.stackController.connectNetwork(modelData.ssid, "", false);
    }
  } }
  footer: Component { Item {
    id: addNetworkRow
    width: PanelStyle.rowWidth
    height: PanelStyle.rowHeight

    Rectangle {
      anchors.fill: parent
      radius: PanelStyle.rowRadius
      color: addNetworkPointer.containsMouse ? PanelStyle.hover
          : Qt.rgba(38 / 255, 38 / 255, 38 / 255, 0)

      Behavior on color {
        ColorAnimation { duration: PanelStyle.controlDuration }
      }
    }

    Row {
      x: 12
      anchors.verticalCenter: parent.verticalCenter
      spacing: 12
      opacity: 0.5
      Image {
        width: 20
        height: 20
        source: Qt.resolvedUrl("../assets/wifi/add.svg")
      }
      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: "Add a network"
        color: "white"
        font.family: Theme.fontFamily
        font.weight: Font.Medium
        font.pixelSize: 15
      }
    }
    MouseArea {
      id: addNetworkPointer
      anchors.fill: parent
      enabled: root.interactive
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: root.stackController.push("add", null)
    }
  } }
}
