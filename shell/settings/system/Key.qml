import QtQuick
import "../.." as Shell

Rectangle {
  id: root
  property string name
  property bool large: false
  property bool active: false
  property bool empty: false
  readonly property color line: active ? Shell.PanelStyle.accent : Qt.rgba(1, 1, 1, 0.15)
  width: large ? 80 : 40; height: width; radius: large ? 8 : 4
  color: "transparent"; border.color: line; opacity: empty ? 0.3 : 1
  Rectangle {
    anchors.centerIn: parent
    width: parent.width * 0.8; height: width; radius: width / 2
    visible: !root.empty
    color: "transparent"; border.color: root.active ? Qt.alpha(root.line, 0.2) : root.line
  }
  Text {
    anchors.centerIn: parent
    text: root.name === "Mod" ? "spr" : root.name.toLowerCase()
    color: Shell.Theme.colors.text
    font.family: Shell.Theme.fontFamily
    font.weight: root.large ? Font.Medium : text.length === 1 ? Font.Bold : Font.DemiBold
    font.pixelSize: root.large ? 15 : text.length === 1 ? 12 : 10
  }
}
