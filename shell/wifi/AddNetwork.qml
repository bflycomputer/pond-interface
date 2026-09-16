import QtQuick
import ".."

Item {
  id: root
  property var stackController
  property bool interactive: true
  property bool dropdownOpen: false
  readonly property bool dropdownVisible: securityMenu.visible
  property string securityValue: "WPA2/WPA3 Personal"
  property string securityMode: "wpa-psk"
  property bool hiddenNetwork: false
  readonly property bool needsPassword: securityMode !== "open"
      && securityMode !== "owe"
  readonly property bool canConnect: networkName.text.length > 0
      && (!needsPassword || password.text.length > 0)

  implicitWidth: PanelStyle.width
  implicitHeight: canConnect ? 435 : 371

  Behavior on implicitHeight {
    NumberAnimation {
      duration: PanelStyle.openDuration
      easing.type: Easing.OutCubic
    }
  }

  PanelBackground { anchors.fill: parent }

  Item {
    id: cardContent
    anchors.fill: parent
    opacity: root.dropdownOpen ? 0.2 : 1
    Behavior on opacity {
      NumberAnimation { duration: PanelStyle.controlDuration }
    }

    Text {
      x: 19.5
      y: 19.5
      text: "Add network"
      color: "white"
      font.family: Theme.titleFontFamily
      font.weight: Font.Normal
      font.pixelSize: 20
    }
    Text {
      x: 19.5
      y: 79.5
      text: "Network name (SSID)"
      color: "white"
      font.family: Theme.fontFamily
      font.weight: Font.Medium
      font.pixelSize: 13
    }
    Field {
      id: networkName
      x: 19.5
      y: 100.5
      placeholderText: "Enter network name"
    }

    Text {
      x: 19.5
      y: 164.5
      text: "Security"
      color: "white"
      font.family: Theme.fontFamily
      font.weight: Font.Medium
      font.pixelSize: 13
    }
    Field {
      id: security
      x: 19.5
      y: 185.5
      text: root.securityValue
      readOnly: true
      highlighted: securityHover.hovered || root.dropdownOpen
      rightPadding: 58
    }
    Item {
      id: securityActivator
      x: 19.5
      y: 185.5
      width: 276
      height: 44

      Item {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 44

        Image {
          anchors.centerIn: parent
          width: 16
          height: 16
          source: Qt.resolvedUrl("../assets/wifi/chevron.svg")
        }
      }
      HoverHandler {
        id: securityHover
        enabled: root.interactive
        cursorShape: Qt.PointingHandCursor
      }
      TapHandler {
        enabled: root.interactive
        onTapped: root.dropdownOpen = !root.dropdownOpen
      }
    }

    Text {
      x: 19.5
      y: 249.5
      text: "Password"
      visible: root.needsPassword
      color: "white"
      font.family: Theme.fontFamily
      font.weight: Font.Medium
      font.pixelSize: 13
    }
    Field {
      password: true
      placeholderText: "Enter password"
      id: password
      x: 19.5
      y: 270.5
      visible: root.needsPassword
      enabled: root.interactive
      onAccepted: if (root.canConnect) connectButton.trigger()
    }

    CheckBox {
      x: 19.5
      y: 326.5
      checked: root.hiddenNetwork
      enabled: root.interactive
      onToggled: checked => root.hiddenNetwork = checked
    }
    Text {
      x: 51.5
      y: 334.5
      text: "Hidden network"
      color: "white"
      font.family: Theme.fontFamily
      font.weight: Font.Medium
      font.pixelSize: 13
    }

    Rectangle {
      id: connectButton
      x: 19.5
      y: 371.5
      width: 276
      height: 48
      radius: 100
      visible: opacity > 0
      opacity: root.canConnect ? 1 : 0
      color: connectHover.hovered ? "#D8B8FA" : PanelStyle.accent

      function trigger() {
        if (root.canConnect)
          root.stackController.connectNetwork(
              networkName.text, password.text, root.hiddenNetwork,
              root.securityMode);
      }
      Text {
        anchors.centerIn: parent
        text: "Connect"
        color: PanelStyle.accentText
        font.family: Theme.fontFamily
        font.weight: Font.Medium
        font.pixelSize: 15
      }
      HoverHandler {
        id: connectHover
        enabled: root.interactive
        cursorShape: Qt.PointingHandCursor
      }
      TapHandler {
        enabled: root.interactive
        onTapped: connectButton.trigger()
      }
    }
  }

  SecurityMenu {
    id: securityMenu
    x: 20
    y: 50
    z: 20
    open: root.dropdownOpen
    currentMode: root.securityMode
    onSelected: (label, mode) => {
      root.securityValue = label;
      root.securityMode = mode;
      root.dropdownOpen = false;
    }
  }

}
