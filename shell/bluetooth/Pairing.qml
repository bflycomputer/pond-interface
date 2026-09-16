import QtQuick
import "." as Bluetooth
import ".." as Shell
Item {
  id: root
  readonly property real headerDividerY: 63.5
  property var stackController
  property bool interactive: true
  property var service: stackController ? stackController.service : Bluetooth.State
  readonly property var prompt: service.prompt
  readonly property bool needsInput: prompt.kind === "pin" || prompt.kind === "passkey"
  readonly property bool canSubmit: prompt.kind === "pin" ? code.text.length > 0 && code.text.length <= 16
      : prompt.kind === "passkey" ? /^\d{1,6}$/.test(code.text) : true
  implicitWidth: Shell.PanelStyle.width
  implicitHeight: 276
  Shell.PanelBackground {
    anchors.fill: parent
    Text {
      x: 20; y: 20; text: "Pair device"; color: "white"
      font.family: Shell.Theme.titleFontFamily; font.pixelSize: 20
    }
    Text {
      x: 20; y: 80; width: 276; height: 56; wrapMode: Text.Wrap
      text: root.prompt.kind === "display" ? "Type this code on your Bluetooth device, then press Enter."
          : root.prompt.kind === "confirm" ? "Confirm that this code matches the one shown on your device."
          : root.needsInput ? "Enter the pairing code shown on your device."
          : "Allow this device to pair?"
      color: "white"; font.family: Shell.Theme.fontFamily; font.pixelSize: 13
    }
    Text {
      x: 20; y: 148; width: 276; horizontalAlignment: Text.AlignHCenter
      visible: !root.needsInput
      text: root.prompt.code || ""
      color: Shell.PanelStyle.accent; font.family: Shell.Theme.fontFamily; font.pixelSize: 28
    }
    Shell.Field {
      id: code; x: 20; y: 144
      visible: root.needsInput
      placeholderText: "Pairing code"
      onAccepted: if (root.canSubmit) root.service.answer(true, text)
    }
    Shell.ActionButton {
      x: 8; y: 228; text: "Cancel"
      interactive: root.interactive
      onClicked: root.service.cancelPairing()
    }
    Shell.ActionButton {
      x: 162; y: 228; text: "Pair"
      visible: root.prompt.kind !== "display"
      interactive: root.interactive && root.canSubmit
      onClicked: root.service.answer(true, code.text)
    }
  }
}
