import QtQuick
import "." as Bluetooth
import ".." as Shell
Item {
  id: root
  readonly property real headerDividerY: 63.5
  readonly property bool headerDividerVisible: !needsInput
  property var stackController
  property bool interactive: true
  property var service: stackController ? stackController.service : Bluetooth.State
  readonly property var prompt: service.prompt
  readonly property bool needsInput: prompt.kind === "pin" || prompt.kind === "passkey"
  readonly property bool canSubmit: prompt.kind === "pin" ? code.text.length > 0 && code.text.length <= 16
      : prompt.kind === "passkey" ? /^\d{1,6}$/.test(code.text) : true
  implicitWidth: Shell.PanelStyle.width
  implicitHeight: needsInput ? 202 : 276
  Shell.PanelBackground {
    anchors.fill: parent
    stacked: true
    Text {
      id: title
      x: 20
      y: root.needsInput ? 23 - baselineOffset + titleMetrics.capitalHeight : 20
      text: "Pair Device"; color: Shell.Theme.colors.text
      font.family: Shell.Theme.titleFontFamily; font.pixelSize: 20
      font.styleName: "Book"
      FontMetrics { id: titleMetrics; font: title.font }
    }
    Text {
      id: instructions
      x: 20
      y: root.needsInput ? 53 - baselineOffset + promptMetrics.capitalHeight : 80
      width: 276; height: root.needsInput ? 19 : 56; wrapMode: Text.Wrap
      text: root.prompt.kind === "display" ? "Type this code on your Bluetooth device, then press Enter."
          : root.prompt.kind === "confirm" ? "Confirm that this code matches the one shown on your device."
          : root.needsInput ? "Enter pairing code shown on your device"
          : "Allow this device to pair?"
      color: Shell.Theme.colors.text; font.family: Shell.Theme.fontFamily; font.pixelSize: 13
      opacity: root.needsInput ? 0.7 : 1
      FontMetrics { id: promptMetrics; font: instructions.font }
    }
    Text {
      x: 20; y: 148; width: 276; horizontalAlignment: Text.AlignHCenter
      visible: !root.needsInput
      text: root.prompt.code || ""
      color: Shell.PanelStyle.accent; font.family: Shell.Theme.fontFamily; font.pixelSize: 28
    }
    Shell.Field {
      id: code; x: 20; y: root.needsInput ? 86 : 144
      visible: root.needsInput
      placeholderText: "Pairing code"
      onAccepted: if (root.canSubmit) root.service.answer(true, text)
    }
    Shell.ActionButton {
      x: 8; y: root.height - 48; text: "Cancel"
      interactive: root.interactive
      onClicked: root.service.cancelPairing()
    }
    Shell.ActionButton {
      x: 162; y: root.height - 48; text: "Pair"
      textOpacity: root.canSubmit ? 0.8 : 0.5
      visible: root.prompt.kind !== "display"
      interactive: root.interactive && root.canSubmit
      onClicked: root.service.answer(true, code.text)
    }
  }
}
