import QtQuick
import ".."

Item {
  id: root
  property var stackController
  property var network: ({})
  property bool interactive: true
  readonly property bool canConnect: password.text.length > 0

  implicitWidth: PanelStyle.width
  implicitHeight: canConnect ? 226 : 167

  Behavior on implicitHeight {
    NumberAnimation {
      duration: PanelStyle.openDuration
      easing.type: Easing.OutCubic
    }
  }

  PanelBackground {
    anchors.fill: parent

    Text {
      x: 19.5
      y: 19.5
      width: 260
      elide: Text.ElideRight
      text: "Join “" + String(root.network.ssid || "Wifi Network") + "”"
      color: "white"
      font.family: Theme.titleFontFamily
      font.weight: Font.Normal
      font.pixelSize: 20
    }
    Text {
      x: 19.5
      y: 79.5
      text: "Password"
      color: "white"
      font.family: Theme.fontFamily
      font.weight: Font.Medium
      font.pixelSize: 15
    }
    PasswordField {
      id: password
      x: 19.5
      y: 102.5
      enabled: root.interactive
      onAccepted: if (root.canConnect) connectButton.trigger()
      onEditingStarted: if (root.stackController)
        root.stackController.beginTextInput()
    }
    Rectangle {
      id: connectButton
      x: 19.5
      y: 162.5
      width: 276
      height: 48
      radius: 100
      visible: opacity > 0
      opacity: root.canConnect ? 1 : 0
      color: connectHover.hovered ? "#D8B8FA" : PanelStyle.accent

      function trigger() {
        if (root.canConnect)
          root.stackController.connectNetwork(
              String(root.network.ssid || ""), password.text, false);
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

}
