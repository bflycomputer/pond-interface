import QtQuick
import "." as Bluetooth
import ".." as Shell
Shell.DeviceDetails {
  id: root
  property var service: stackController ? stackController.service : Bluetooth.State
  readonly property var device: service.deviceFor(selection.path || "")
  title: device ? device.name : "Device unavailable"
  detailRows: {
    if (!device) return [{label: "Status", value: "This device is no longer available."}];
    const rows = [
      {label: "Device type", value: device.type},
      {label: "Bluetooth address", value: device.address},
      {label: "Connection", value: device.connected ? "Connected" : "Disconnected"},
      {label: "Pairing", value: device.paired || device.bonded ? "Paired" : "Not paired"}
    ];
    if (device.battery >= 0 && device.connected)
      rows.push({label: "Battery", value: device.battery + "%"});
    if (device.model) rows.push({label: "Model", value: device.model});
    if (device.deviceName && device.deviceName !== device.name)
      rows.push({label: "Device name", value: device.deviceName});
    return rows;
  }
  primaryEnabled: !!device && (device.paired || device.bonded) && !service.isBusy(device.path)
  secondaryEnabled: !!device && service.enabled && !service.isBusy(device.path)
  secondaryText: device && service.isBusy(device.path) ? "Working…"
      : device && device.connected ? "Disconnect" : "Connect"
  message: service.errorText
  onPrimaryClicked: service.forget(device)
  onSecondaryClicked: service.activate(device)
}
