pragma Singleton
import Quickshell
import Quickshell.Services.UPower

Singleton {
  readonly property UPowerDevice device: UPower.displayDevice
  readonly property bool present: device.ready && device.isPresent
      && device.type === UPowerDeviceType.Battery
  readonly property real percentage: present ? Math.max(0, Math.min(100, device.percentage * 100)) : 0
  readonly property bool charging: present && device.state === UPowerDeviceState.Charging
  readonly property string description: present
      ? "Battery " + Math.round(percentage) + "%, " + UPowerDeviceState.toString(device.state) : ""
}
