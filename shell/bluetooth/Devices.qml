pragma ComponentBehavior: Bound
import QtQuick
import "." as Bluetooth
import ".." as Shell
Shell.DeviceList {
  id: root
  property var service: stackController ? stackController.service : Bluetooth.State
  title: "Bluetooth"
  titleIcon: Qt.resolvedUrl("../assets/bluetooth/bluetooth.svg")
  listBottomPadding: 8
  viewportHeight: 292
  devices: service.enabled ? service.pairedDevices : []
  emptyText: !service.available ? "No Bluetooth adapter found."
      : service.blocked ? "Bluetooth is blocked. Turn off airplane mode to enable it."
      : !service.enabled ? "Bluetooth is off."
      : "No paired devices. Search nearby to pair a device."
  message: service.errorText
  headerControl: Component { Shell.Toggle {
    checked: root.service.enabled
    enabled: root.interactive && root.service.available && !root.service.powerBusy
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
    label: "Search nearby devices"
    labelGap: 12; labelSize: 15; labelRight: 290; contentOpacity: 0.5
    interactive: root.interactive && root.service.enabled
    leading: Component { Image { source: Qt.resolvedUrl("../assets/bluetooth/search.svg") } }
    onClicked: root.stackController.openNearby()
  } }
}
