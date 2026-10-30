pragma ComponentBehavior: Bound
import QtQuick
import "." as Bluetooth
import ".." as Shell
Shell.DeviceList {
  id: root
  readonly property real headerDividerY: 63.5
  property var service: stackController ? stackController.service : Bluetooth.State
  title: qsTrId("pond.nearby_devices")
  listBottomPadding: 8
  viewportHeight: 316
  listTop: 68
  devices: service.enabled ? service.nearbyDevices : []
  deviceKey: "path"
  emptyText: !service.enabled ? qsTrId("pond.bluetooth_is_off")
      : service.discovering ? qsTrId("pond.searching_for_devices_make_sure_your_device_is_in_pairing_mode")
      : qsTrId("pond.no_nearby_devices_found")
  message: service.errorText
  headerControl: Component { Item {
    StatusAnimation {
      x: 25; width: 28; height: 28
      visible: root.service.discovering
      running: root.service.discovering && root.interactive
      firstFrame: Qt.resolvedUrl("../assets/bluetooth/searching-1.svg")
      secondFrame: Qt.resolvedUrl("../assets/bluetooth/searching-2.svg")
    }
  } }
  deviceDelegate: Component { DeviceRow {
    required property var modelData
    device: modelData; service: root.service
    interactive: root.interactive
    onClicked: root.stackController.connectNearby(modelData)
    onInfoClicked: root.stackController.openDetails(modelData)
  } }
}
