import QtQuick
import "../.." as Shell
Rectangle {
  id: root
  property string label
  property bool selected: false
  property bool arranging: false
  property bool dragging: false
  property bool hovered: false
  radius: 12
  color: selected || dragging ? "#3f3847" : hovered || activeFocus ? (arranging ? "#525252" : "#303030") : arranging ? "#303030" : "#262626"
  border.width: selected || dragging ? 1 : 0
  border.color: "#cba6f7"
  Text {
    anchors.centerIn: parent
    width: parent.width - 16
    text: root.label
    color: root.selected || root.dragging ? "#cba6f7" : "#b3b3b3"
    font.family: Shell.Theme.fontFamily
    font.pixelSize: 13; font.weight: Font.Medium
    horizontalAlignment: Text.AlignHCenter
    wrapMode: Text.Wrap; maximumLineCount: 2; elide: Text.ElideRight
  }
}
