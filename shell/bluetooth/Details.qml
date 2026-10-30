import QtQuick
import "." as Bluetooth
import ".." as Shell
Shell.DeviceDetails {
  id: root
  property var service: stackController ? stackController.service : Bluetooth.State
  readonly property var device: service.deviceFor(selection.path || "")
  title: device ? device.name : qsTrId("pond.device_unavailable")
  detailRows: {
    if (!device) return [{label: qsTrId("pond.status"), value: qsTrId("pond.this_device_is_no_longer_available")}];
    const rows = [
      {label: qsTrId("pond.device_type"), value: device.type},
      {label: qsTrId("pond.bluetooth_address"), value: device.address},
      {label: qsTrId("pond.connection"), value: device.connected ? qsTrId("pond.connected") : qsTrId("pond.disconnected")},
      {label: qsTrId("pond.pairing"), value: device.paired || device.bonded ? qsTrId("pond.paired") : qsTrId("pond.not_paired")}
    ];
    if (device.battery >= 0 && device.connected)
      rows.push({label: qsTrId("pond.battery"), value: device.battery + "%"});
    if (device.model) rows.push({label: qsTrId("pond.model"), value: device.model});
    if (device.deviceName && device.deviceName !== device.name)
      rows.push({label: qsTrId("pond.device_name"), value: device.deviceName});
    return rows;
  }
  primaryEnabled: !!device && (device.paired || device.bonded) && !service.isBusy(device.path)
  secondaryEnabled: !!device && service.enabled && !service.isBusy(device.path)
  secondaryText: device && service.isBusy(device.path) ? qsTrId("pond.working")
      : device && device.connected ? qsTrId("pond.disconnect") : qsTrId("pond.connect")
  message: service.errorText
  onPrimaryClicked: service.forget(device)
  onSecondaryClicked: service.activate(device)
}
