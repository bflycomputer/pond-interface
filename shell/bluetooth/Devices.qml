pragma ComponentBehavior: Bound
import QtQuick
import "." as Bluetooth
import ".." as Shell
Shell.DeviceList {
  id: root
  property var service: stackController ? stackController.service : Bluetooth.State
  title: qsTrId("pond.bluetooth")
  titleIcon: Qt.resolvedUrl("../assets/bluetooth/bluetooth.svg")
  listBottomPadding: 8
  viewportHeight: 292
  devices: service.enabled ? service.pairedDevices : []
  deviceKey: "path"
  emptyText: !service.available ? qsTrId("pond.no_bluetooth_adapter_found")
      : service.blocked ? qsTrId("pond.bluetooth_is_blocked_turn_off_airplane_mode_to_enable_it")
      : !service.enabled ? qsTrId("pond.bluetooth_is_off")
      : qsTrId("pond.no_paired_devices_search_nearby_to_pair_a_device")
  message: service.errorText
  headerControl: Component { Shell.Toggle {
    checked: root.service.enabled
    enabled: root.interactive && root.service.available
    busy: root.service.powerBusy
    onToggled: checked => root.service.setEnabled(checked)
  } }
  deviceDelegate: Component { DeviceRow {
    required property var modelData
    device: modelData; service: root.service
    interactive: root.interactive
    onClicked: root.service.activate(modelData)
    onInfoClicked: root.stackController.openDetails(modelData)
  } }
  footer: Component { Bluetooth.Row {
    label: qsTrId("pond.search_nearby_devices")
    labelGap: 12; labelSize: 15; labelRight: 290; contentOpacity: 0.5
    interactive: root.interactive && root.service.enabled
    leading: Component { Image { source: Qt.resolvedUrl("../assets/bluetooth/search.svg") } }
    onClicked: root.stackController.openNearby()
  } }
}
