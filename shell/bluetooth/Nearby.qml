pragma ComponentBehavior: Bound
import QtQuick
import "." as Bluetooth
import ".." as Shell
Shell.DeviceList {
  id: root
  readonly property real headerDividerY: 63.5
  property var service: stackController ? stackController.service : Bluetooth.State
  title: "Nearby devices"
  listBottomPadding: 8
  viewportHeight: 316
  listTop: 68
  devices: service.enabled ? service.nearbyDevices : []
  deviceKey: "path"
  emptyText: !service.enabled ? "Bluetooth is off."
      : service.discovering ? "Searching for devices…\nMake sure your device is in pairing mode."
      : "No nearby devices found."
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
