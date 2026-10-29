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
    "WheelScrollLeft": "scroll\u2190", "WheelScrollRight": "scroll\u2192",
    "XF86AudioRaiseVolume": "vol+", "XF86AudioLowerVolume": "vol\u2212",
    "XF86AudioMute": "mute", "XF86AudioMicMute": "mic",
    "XF86AudioPlay": "play", "XF86AudioPause": "pause",
    "XF86AudioNext": "next", "XF86AudioPrev": "prev",
    "XF86MonBrightnessUp": "light+", "XF86MonBrightnessDown": "light\u2212",
    "Print": "print", "CapsLock": "caps", "Insert": "ins"
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
