import QtQuick
import ".."

Item {
  id: root
  readonly property real headerDividerY: 63.5
  readonly property bool headerDividerVisible: !optionsMenu.visible || optionsMenu.y > headerDividerY
  property var stackController
  property var selection: ({})
  property bool interactive: true
  property var menu: ({})
  property bool dropdownOpen: false
  readonly property bool isEnterprise: selection.enterprise === true
  readonly property bool canConnect: isEnterprise ? enterprise.complete : password.text.length > 0

  implicitWidth: PanelStyle.width
  implicitHeight: isEnterprise ? connectButton.y + (canConnect ? 63.5 : 0.5)
                               : canConnect ? 226 : 167

  function focusEditor() {
    if (isEnterprise) enterprise.focusEditor();
    else password.focusEditor();
  }
  Component.onCompleted: if (interactive) focusEditor()
  onInteractiveChanged: if (interactive) focusEditor()

  Behavior on implicitHeight {
    NumberAnimation {
      duration: PanelStyle.openDuration
      easing.type: Easing.OutCubic
    }
  }

  PanelBackground { anchors.fill: parent }
  Item {
    anchors.fill: parent
    enabled: root.interactive && !root.dropdownOpen
    opacity: root.dropdownOpen ? 0.2 : 1
    Behavior on opacity {
      NumberAnimation { duration: PanelStyle.controlDuration }
    }

    Text {
      x: 19.5
      y: 19.5
      width: 260
      elide: Text.ElideRight
      text: "Join “" + String(root.selection.ssid || "Wifi Network") + "”"
      color: "white"
      font.family: Theme.titleFontFamily
      font.weight: Font.Normal
      font.pixelSize: 20
    }
    Text {
      x: 19.5
      y: 79.5
      text: "Password"
      visible: !root.isEnterprise
      color: "white"
      font.family: Theme.fontFamily
      font.weight: Font.Medium
      font.pixelSize: 15
    }
    Field {
      id: password
      x: 19.5
      y: 102.5
      visible: !root.isEnterprise
      password: true
      placeholderText: "Enter password"
      onAccepted: connectButton.trigger()
    }
    FormViewport {
      id: form
      y: 79.5
      width: parent.width
      height: 416
      contentHeight: enterprise.height
      visible: root.isEnterprise
      EnterpriseFields {
        id: enterprise
        x: 19.5
        onFieldFocused: field => form.reveal(field)
        onAccepted: connectButton.trigger()
        onMenuRequested: menu => { root.menu = menu; root.dropdownOpen = true; }
      }
    }
    Rectangle {
      id: connectButton
      x: 19.5
      y: root.isEnterprise ? form.y + form.height + 16 : 162.5
      width: 276
      height: 48
      radius: 100
      visible: opacity > 0
      opacity: root.canConnect ? 1 : 0
      color: connectHover.hovered ? "#D8B8FA" : PanelStyle.accent

      function trigger() {
        if (root.canConnect)
          root.stackController.connectNetwork(
              String(root.selection.ssid || ""),
              root.isEnterprise ? enterprise.secret : password.text, false,
              root.isEnterprise ? "wpa-eap" : "auto",
              root.isEnterprise ? enterprise.settings : undefined);
      }

      Behavior on opacity {
        NumberAnimation { duration: PanelStyle.controlDuration }
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
    id: optionsMenu
    z: 20
    open: root.dropdownOpen
    anchorItem: root.menu?.anchor ?? null
    options: root.menu?.options ?? []
    currentMode: root.menu?.mode ?? ""
    onDismissed: root.dropdownOpen = false
    onSelected: (label, mode) => {
      enterprise.select(root.menu.setting, mode);
      root.dropdownOpen = false;
    }
  }
}
