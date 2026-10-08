import QtQuick
import ".."

Item {
  id: root
  readonly property real headerDividerY: 63.5
  readonly property bool headerDividerVisible: !securityMenu.visible || securityMenu.y > headerDividerY
  property var stackController
  property bool interactive: true
  property var menu: ({})
  property bool dropdownOpen: false
  property string securityValue: "WPA2/WPA3 Personal"
  property string securityMode: "wpa-psk"
  property bool hiddenNetwork: false
  readonly property bool isEnterprise: securityMode === "wpa-eap"
  readonly property bool needsPassword: securityMode !== "open"
      && securityMode !== "owe" && !isEnterprise
  readonly property bool canConnect: networkName.text.length > 0
      && (isEnterprise ? enterprise.complete : !needsPassword || password.text.length > 0)

  implicitWidth: PanelStyle.width
  implicitHeight: connectButton.y + (canConnect ? 63.5 : isEnterprise ? 0.5 : -0.5)
  onSecurityModeChanged: form.contentY = 0

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
    enabled: root.interactive && !root.dropdownOpen
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

    FormViewport {
      id: form
      y: 79.5
      width: parent.width
      height: root.isEnterprise ? 416 : 292
      contentHeight: hidden.y + 44

      Text {
        x: 19.5
        text: "Network name (SSID)"
        color: "white"
        font.family: Theme.fontFamily
        font.weight: Font.Medium
        font.pixelSize: 13
      }
      Field {
        id: networkName
        x: 19.5
        y: 21
        placeholderText: "Enter network name"
        onFocusedChanged: if (focused) form.reveal(this)
      }
      Text {
        x: 19.5
        y: 85
        text: "Security"
        color: "white"
        font.family: Theme.fontFamily
        font.weight: Font.Medium
        font.pixelSize: 13
      }
      SelectField {
        x: 19.5
        y: 106
        text: root.securityValue
        onActiveFocusChanged: if (activeFocus) form.reveal(this)
        onClicked: {
          root.menu = {setting: "security", options: securityMenu.securityOptions,
                       mode: root.securityMode, anchor: this};
          root.dropdownOpen = true;
        }
      }

      Text {
        x: 19.5
        y: 170
        text: "Password"
        visible: root.needsPassword
        color: "white"
        font.family: Theme.fontFamily
        font.weight: Font.Medium
        font.pixelSize: 13
      }
      Field {
        id: password
        x: 19.5
        y: 191
        password: true
        placeholderText: "Enter password"
        visible: root.needsPassword
        onAccepted: connectButton.trigger()
      }
      EnterpriseFields {
        id: enterprise
        x: 19.5
        y: 170
        visible: root.isEnterprise
        onFieldFocused: field => form.reveal(field)
        onAccepted: connectButton.trigger()
        onMenuRequested: menu => { root.menu = menu; root.dropdownOpen = true; }
      }

      CheckBox {
        id: hidden
        x: 19.5
        y: root.isEnterprise ? enterprise.y + enterprise.height + 12 : 247
        checked: root.hiddenNetwork
        onToggled: checked => root.hiddenNetwork = checked
      }
      Text {
        x: 51.5
        anchors.verticalCenter: hidden.verticalCenter
        text: "Hidden network"
        color: "white"
        font.family: Theme.fontFamily
        font.weight: Font.Medium
        font.pixelSize: 13
      }
    }

    Rectangle {
      id: connectButton
      x: 19.5
      y: form.y + form.height + (root.isEnterprise ? 16 : 0)
      width: 276
      height: 48
      radius: 100
      visible: opacity > 0
      opacity: root.canConnect ? 1 : 0
      color: connectHover.hovered ? "#D8B8FA" : PanelStyle.accent

      function trigger() {
        if (root.canConnect)
          root.stackController.connectNetwork(
              networkName.text, root.isEnterprise ? enterprise.secret : password.text,
              root.hiddenNetwork, root.securityMode,
              root.isEnterprise ? enterprise.settings : undefined);
      }
      Text {
        anchors.centerIn: parent
        text: "Connect"
        color: PanelStyle.accentText
        font.family: Theme.fontFamily
        font.weight: Font.Medium
        font.pixelSize: 15
      }
      HoverHandler { id: connectHover; cursorShape: Qt.PointingHandCursor }
      TapHandler { onTapped: connectButton.trigger() }
    }
  }

  Item {
    anchors.fill: parent
    enabled: root.interactive && root.dropdownOpen
    TapHandler { onTapped: root.dropdownOpen = false }
  }
  SecurityMenu {
    id: securityMenu
    z: 20
    open: root.dropdownOpen
    anchorItem: root.menu?.anchor ?? null
    options: root.menu?.options ?? []
    currentMode: root.menu?.mode ?? ""
    onDismissed: root.dropdownOpen = false
    onSelected: (label, mode) => {
      if (root.menu.setting === "security") {
        root.securityValue = label;
        root.securityMode = mode;
      } else {
        enterprise.select(root.menu.setting, mode);
      }
      root.dropdownOpen = false;
    }
  }
}
