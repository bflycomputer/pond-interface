import QtQuick
import "." as Wifi
import ".."

DeviceDetails {
  id: root
  readonly property bool connected: selection.ssid === Wifi.State.connectedSsid
  title: String(selection.ssid || Wifi.State.connectedSsid)
  titleIcon: Component { SignalIcon { bars: Number(root.selection.bars || 3) } }
  primaryEnabled: (selection.uuids || []).length > 0
  secondaryText: connected ? qsTrId("pond.disconnect") : qsTrId("pond.connect")
  detailRows: connected ? [
    {label: qsTrId("pond.link_speed"), value: Wifi.State.linkSpeed},
    {label: qsTrId("pond.ipv4_address"), value: Wifi.State.ipv4},
    {label: qsTrId("pond.band_channel_width"), value: Wifi.State.band},
    {label: qsTrId("pond.default_gateway"), value: Wifi.State.gateway},
    {label: qsTrId("pond.dns_server"), value: Wifi.State.dns},
    {label: qsTrId("pond.network_interface"), value: Wifi.State.device || "—"}
  ] : []
  Component.onCompleted: Wifi.State.refreshDetails()
  onPrimaryClicked: {
    Wifi.State.forget(selection);
    stackController.showStatus();
  }
  onSecondaryClicked: {
    if (connected) {
      Wifi.State.disconnect();
      stackController.showStatus();
    } else {
      stackController.connectNetwork(selection.ssid, "", false);
    }
  }
}
