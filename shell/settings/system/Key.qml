import QtQuick
import "../.." as Shell

Rectangle {
  id: root
  property string name
  property bool large: false
  property bool active: false
  property bool empty: false
  readonly property string key: name.toLowerCase()
  readonly property string icon: ({equal: "plus", plus: "plus", minus: "minus", return: "enter", space: "space"})[key] ?? ""
  readonly property color line: active ? Shell.PanelStyle.accent : Qt.rgba(1, 1, 1, 0.2)
  width: large ? 80 : 40; height: width; radius: large ? 8 : 4
  color: "transparent"; border.color: line; opacity: empty ? 0.3 : 1
  Rectangle {
    anchors.centerIn: parent
    width: parent.width * 0.8; height: width; radius: width / 2
    visible: !root.empty
    color: "transparent"; border.color: root.active ? Qt.alpha(root.line, 0.2) : root.line
  }
  Image {
    anchors.centerIn: parent
    visible: !!root.icon
    width: root.large ? 24 : 16; height: width; sourceSize: Qt.size(width * 2, height * 2)
    source: root.icon ? Qt.resolvedUrl("../../assets/keys/" + root.icon + ".svg") : ""
  }
  Text {
    readonly property real capHeight: font.pixelSize * 0.707
    visible: !root.icon
    x: (root.width - width) / 2
    y: root.height / 2 - Math.ceil(capHeight / 2) + capHeight - baselineOffset
    text: ({mod: "spr", escape: "esc", delete: "del"})[root.key] ?? root.key
    color: Shell.Theme.colors.text
    font.family: Shell.Theme.fontFamily
    font.weight: root.large ? Font.Medium : Font.DemiBold
    font.pixelSize: root.large ? 15 : 10
    font.letterSpacing: root.large ? 0 : 0.1
  }
}
