pragma ComponentBehavior: Bound
import QtQuick
import "." as Wifi
import ".."

Item {
  id: root
  property var stackController
  property var network: ({})
  property bool interactive: true
  readonly property var detailRows: [
    {label: "Link Speed", value: Wifi.State.linkSpeed},
    {label: "IPv4 Address", value: Wifi.State.ipv4},
    {label: "Band / Channel / Width", value: Wifi.State.band},
    {label: "Default Gateway", value: Wifi.State.gateway},
    {label: "DNS Server", value: Wifi.State.dns},
    {label: "Network Interface", value: (Wifi.State.device || "—")}
  ]
  Component.onCompleted: Wifi.State.refreshDetails()
  implicitWidth: PanelStyle.width
  implicitHeight: 120 + detailRows.length * 50

  PanelBackground {
    anchors.fill: parent
    Text {
      x: 19.5; y: 19.5; width: 245
      elide: Text.ElideRight
      text: String(root.network.ssid || Wifi.State.connectedSsid); color: "white"
      font.family: Theme.titleFontFamily; font.weight: Font.Normal; font.pixelSize: 20
    }
    SignalIcon { x: 275.5; y: 23.5; width: 20; height: 20; bars: Number(root.network.bars || 3) }
    Column {
      x: 19.5; y: 75.5; spacing: 20
      Repeater {
        model: root.detailRows
        delegate: DetailLine {
          required property var modelData
          label: modelData.label
          value: String(modelData.value)
        }
      }
    }
    ActionButton {
      x: 7.5; y: parent.height - 48.5
      text: "Forget"
      interactive: root.interactive
      onClicked: {
        Wifi.State.forget(String(root.network.ssid || Wifi.State.connectedSsid));
        root.stackController.showStatus();
      }
    }
    ActionButton {
      x: 161.5; y: parent.height - 48.5
      text: "Disconnect"
      interactive: root.interactive
      onClicked: {
        Wifi.State.disconnect();
        root.stackController.showStatus();
      }
    }
  }
}
