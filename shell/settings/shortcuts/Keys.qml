import QtQuick
import "." as Shortcuts
import "../.." as Shell

// Keycap chips in the manual/Picker style: "spr"-shaped modifier chips plus
// one bold key chip. Given a chord like "Mod+Shift+ESCAPE".
Row {
  id: root
  property string chord: ""
  property real size: 24
  spacing: 4

  readonly property var parts: chord.split("+")
  // Kept in State so search can match what users see spelled on the chips.
  readonly property var labels: Shortcuts.State.chipNames

  Accessible.role: Accessible.StaticText
  Accessible.name: root.parts.join(" plus ")

  Repeater {
    model: root.parts

    Rectangle {
      id: chip
      required property string modelData
      required property int index
      readonly property bool last: index === root.parts.length - 1
      readonly property string text: root.labels[modelData] !== undefined
          ? root.labels[modelData] : modelData.toLowerCase()

      height: root.size
      width: label.width + 14
      radius: 4
      color: "transparent"
      border.width: 1
      border.color: "#4a4a4a"

      Text {
        id: label
        anchors.centerIn: parent
        text: chip.text.length > 9 ? chip.text.slice(0, 8) + "\u2026" : chip.text
        color: "white"
        font.family: Shell.Theme.fontFamily
        font.weight: chip.last ? Font.Bold : Font.DemiBold
        font.pixelSize: chip.last ? 11 : 10
      }
    }
  }
}
