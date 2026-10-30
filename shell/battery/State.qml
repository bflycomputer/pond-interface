pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.UPower

Singleton {
  id: root
  readonly property UPowerDevice device: UPower.displayDevice
  readonly property bool present: device.ready && device.isPresent
      && device.type === UPowerDeviceType.Battery
  readonly property real percentage: present ? Math.max(0, Math.min(100, device.percentage * 100)) : 0
  readonly property bool charging: present && (device.state === UPowerDeviceState.Charging || !UPower.onBattery)
  readonly property string description: present
      ? qsTrId("pond.battery_1_2").arg(Math.round(percentage)).arg(({[UPowerDeviceState.Charging]: qsTrId("pond.charging"), [UPowerDeviceState.Discharging]: qsTrId("pond.discharging"), [UPowerDeviceState.Empty]: qsTrId("pond.empty"), [UPowerDeviceState.FullyCharged]: qsTrId("pond.charged"), [UPowerDeviceState.PendingCharge]: qsTrId("pond.pending_charge"), [UPowerDeviceState.PendingDischarge]: qsTrId("pond.pending_discharge"), [UPowerDeviceState.Unknown]: qsTrId("pond.unknown")})[device.state] || qsTrId("pond.unknown")) : ""
  readonly property int level: Math.round(percentage)
  readonly property bool low: present && !charging && level <= 10
  readonly property color lowColor: level <= 3 ? "#FD6164" : level <= 5 ? "#FF9F67" : "#FFDC67"
  readonly property color lowSurface: level <= 3 ? "#3E2222" : level <= 5 ? "#342A24" : "#343024"
  readonly property int alertLevel: !low ? 0 : level <= 3 ? 3 : level <= 5 ? 5 : 10
  property int alert: 0
  property int alerted: 0
  readonly property var profiles: [
    { profile: PowerProfile.PowerSaver, name: qsTrId("pond.eco"), icon: "eco", accent: "#CBE25B" },
    { profile: PowerProfile.Balanced, name: qsTrId("pond.balanced"), icon: "balanced", accent: "#E99FFF" },
    { profile: PowerProfile.Performance, name: qsTrId("pond.performance"), icon: "performance", accent: "#FFE51D" }
  ]

  onChargingChanged: if (charging) { alerted = 0; alert = 0; }
  onAlertLevelChanged: {
    if (alertLevel === 0 || (alerted && alertLevel >= alerted)) return;
    alerted = alertLevel;
    alert = alertLevel;
    if (alertLevel === 3) alertTimer.stop();
    else alertTimer.restart();
  }

  Timer {
    id: alertTimer
    interval: 5000
    onTriggered: root.alert = 0
  }
}
