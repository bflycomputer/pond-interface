pragma ComponentBehavior: Bound
import QtQuick
import "." as Wifi
import ".."

Item {
  id: root
  property var stackController
  property bool interactive: true
  implicitWidth: PanelStyle.width
  implicitHeight: 306

  PanelBackground {
    anchors.fill: parent
    Text {
      x: 19.5; y: 19.5
      text: "Wifi"
      color: "white"
      font.family: Theme.titleFontFamily
      font.pixelSize: 20
    }
    Toggle {
      x: 241.5; y: 19.5; width: 54; height: 28
      checked: Wifi.State.enabled
      enabled: root.interactive
      onToggled: checked => Wifi.State.setWifiEnabled(checked)
    }
    ScrollList {
      id: deviceList
      rowHeight: PanelStyle.rowHeight
      x: 8; y: 64; width: PanelStyle.rowWidth
      height: parent.height - y
      model: Wifi.State.enabled ? Wifi.State.networks : []
      footerPositioning: ListView.InlineFooter
      delegate: NetworkRow {
        required property var modelData
        width: PanelStyle.rowWidth
        network: modelData
        interactive: root.interactive
        onDisconnectClicked: Wifi.State.disconnect()
        onRowClicked: {
          if (modelData.connected)
            root.stackController.openDetails(modelData);
          else if (modelData.locked)
            root.stackController.openJoin(modelData);
          else
            root.stackController.connectNetwork(modelData.ssid, "", false);
        }
      }
      footer: Item {
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
          onClicked: root.stackController.openAddNetwork()
        }
      }
    }
    Rectangle {
      x: 0; y: 60; width: parent.width; height: 16
      visible: deviceList.contentY > 0.5
      opacity: visible ? 1 : 0
      gradient: Gradient {
        GradientStop { position: 0; color: Qt.rgba(0, 0, 0, 0.20) }
        GradientStop { position: 1; color: "transparent" }
      }
      Behavior on opacity { NumberAnimation { duration: PanelStyle.controlDuration } }
    }
  }
}
