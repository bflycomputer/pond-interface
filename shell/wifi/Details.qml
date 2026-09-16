import QtQuick
import "." as Wifi
import ".."

DeviceDetails {
  id: root
  title: String(selection.ssid || Wifi.State.connectedSsid)
  titleIcon: Component { SignalIcon { bars: Number(root.selection.bars || 3) } }
  detailRows: [
    {label: "Link Speed", value: Wifi.State.linkSpeed},
    {label: "IPv4 Address", value: Wifi.State.ipv4},
    {label: "Band / Channel / Width", value: Wifi.State.band},
    {label: "Default Gateway", value: Wifi.State.gateway},
    {label: "DNS Server", value: Wifi.State.dns},
    {label: "Network Interface", value: Wifi.State.device || "—"}
  ]
  Component.onCompleted: Wifi.State.refreshDetails()
  onPrimaryClicked: {
    Wifi.State.forget();
    stackController.showStatus();
  }
  onSecondaryClicked: {
    Wifi.State.disconnect();
    stackController.showStatus();
  }
}
