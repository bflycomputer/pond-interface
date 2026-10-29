import QtQuick
import "wifi" as Wifi

// The connection name with live upload and download rates.
FeedbackCard {
  id: root
  readonly property bool connected: Wifi.State.wifiConnected || Wifi.State.wiredConnected
  readonly property bool noInternet: Wifi.State.internetUnavailable && connected
  title: Wifi.State.wiredConnected ? Wifi.State.wiredNetworks[0].name
      : Wifi.State.wifiConnected ? Wifi.State.connectedSsid || "Wi-Fi"
      : Wifi.State.enabled ? "Not connected" : "Wi-Fi off"
  Component.onCompleted: Wifi.State.setRateConsumer(root, true)
  Component.onDestruction: Wifi.State.setRateConsumer(root, false)

  Text {
    anchors.verticalCenter: parent.verticalCenter
    visible: root.noInternet || !root.connected
    text: root.noInternet ? "No internet" : "Click to connect"
    color: "white"
    opacity: 0.6
    font.family: Theme.fontFamily
    font.weight: Font.Medium
    font.pixelSize: 13
  }

  Row {
    anchors.centerIn: parent
    visible: root.connected && !root.noInternet
    spacing: 6

    Repeater {
      model: [
        {icon: "upload.svg", rate: Wifi.State.uploadRate},
        {icon: "download.svg", rate: Wifi.State.downloadRate}
      ]
      Row {
        id: rate
        required property var modelData
        required property int index
        height: 19
        spacing: 4

        Rectangle {
          visible: rate.index > 0
          width: 1
          height: 14
          anchors.verticalCenter: parent.verticalCenter
          color: Theme.sidebarV3Foreground
          opacity: 0.24
        }
        Item { visible: rate.index > 0; width: 2; height: 1 }
        Image {
          width: 12
          height: 12
          anchors.verticalCenter: parent.verticalCenter
          source: Qt.resolvedUrl("assets/wifi/" + rate.modelData.icon)
          opacity: 0.6
        }
        Text {
          height: 19
          text: rate.modelData.rate
          color: "white"
          opacity: 0.6
          font.family: Theme.fontFamily
          font.weight: Font.Medium
          font.pixelSize: 13
          font.features: { "tnum": 1 }
          verticalAlignment: Text.AlignVCenter
        }
      }
    }
  }
}
