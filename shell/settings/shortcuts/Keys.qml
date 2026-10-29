import QtQuick
import "../.." as Shell

// Keycap chips in the manual/Picker style: "spr"-shaped modifier chips plus
// one bold key chip. Given a chord like "Mod+Shift+ESCAPE".
Row {
  id: root
  property string chord: ""
  property real size: 24
  spacing: 4

  readonly property var parts: chord.split("+")
  readonly property var labels: ({
    "Mod": "spr", "Super": "spr", "Shift": "shift", "Ctrl": "ctrl", "ALT": "alt",
    "Return": "enter", "ESCAPE": "esc", "Backspace": "backspace",
    "WheelScrollUp": "scroll\u2191", "WheelScrollDown": "scroll\u2193",
    "WheelScrollLeft": "scroll\u2190", "WheelScrollRight": "scroll\u2192"
  })

  Accessible.role: Accessible.StaticText
  Accessible.name: root.parts.join(" plus ")

  Repeater {
    model: root.parts

    Rectangle {
      id: chip
      required property string modelData
      required property int index
      readonly property bool last: index === root.parts.length - 1
      readonly property bool small: labels[modelData] !== undefined
          ? labels[modelData].length > 3 : modelData.length > 1

      height: root.size
      width: text.width + (small ? 12 : 16)
      radius: 4
      color: "transparent"
      border.width: 1
      border.color: "#4a4a4a"

      Text {
        id: text
        anchors.centerIn: parent
        text: {
          const named = root.labels[chip.modelData];
          if (named !== undefined) return named;
          const truncated = chip.modelData.length > 7 ? chip.modelData.slice(0, 6) + "\u2026" : chip.modelData;
          return chip.last ? truncated.toLowerCase() : truncated.toLowerCase();
        }
        color: "white"
        font.family: Shell.Theme.fontFamily
        font.weight: chip.last ? Font.Bold : Font.DemiBold
        font.pixelSize: chip.last ? 11 : 10
      }
    }
  }
}
