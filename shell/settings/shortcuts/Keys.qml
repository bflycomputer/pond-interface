pragma ComponentBehavior: Bound

import QtQuick
import "." as Shortcuts
import "../.." as Shell

// Keycap chips in the manual/Picker style: "spr"-shaped modifier chips plus
// one bold key chip. Given a chord like "Mod+Shift+ESCAPE".
Row {
  id: root
  property string chord: ""
  property real size: 24
  // False while recording with only modifiers held: no chip is the key yet.
  property bool complete: true
  property color borderColor: "#4a4a4a"
  spacing: 4

  readonly property var parts: chord === "" ? [] : chord.split("+")

  Accessible.role: Accessible.StaticText
  Accessible.name: root.parts.join(" plus ")

  Repeater {
    model: root.parts

    Rectangle {
      id: chip
      required property string modelData
      required property int index
      readonly property bool key: root.complete && index === root.parts.length - 1
      readonly property string text: Shortcuts.State.chipText(modelData)

      height: root.size
      width: label.width + 14
      radius: 4
      color: "transparent"
      border.width: 1
      border.color: root.borderColor

      Text {
        id: label
        anchors.centerIn: parent
        text: chip.text.length > 9 ? chip.text.slice(0, 8) + "…" : chip.text
        color: "white"
        font.family: Shell.Theme.fontFamily
        font.weight: chip.key ? Font.Bold : Font.DemiBold
        font.pixelSize: chip.key ? 11 : 10
      }
    }
  }
}
