import QtQuick
import "../.." as Shell

// A pill in a small either/or choice ("App" / "Shell script").
Rectangle {
  id: choice
  property string label
  property bool selected
  signal picked
  width: choiceText.implicitWidth + 28; height: 28; radius: 14
  color: selected ? "#303030" : choiceHover.hovered ? "#262626" : "transparent"
  border.width: 1; border.color: "#303030"
  Accessible.role: Accessible.RadioButton
  Accessible.name: label
  Accessible.checked: selected
  Text {
    id: choiceText
    anchors.centerIn: parent; text: choice.label; color: "white"
    opacity: choice.selected ? 0.9 : 0.5
    font.family: Shell.Theme.fontFamily; font.pixelSize: 12
  }
  HoverHandler { id: choiceHover; cursorShape: Qt.PointingHandCursor }
  TapHandler { onTapped: choice.picked() }
}
