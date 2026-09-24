import QtQuick
import "../.." as Shell
Rectangle {
  id: root
  property string title
  property string value
  property bool highlighted: false
  property bool toggle: false
  property bool checked: false
  signal clicked
  signal toggled(bool checked)
  width: 520; height: 51; radius: 12
  color: highlighted || hover.hovered || activeFocus ? "#303030" : "#262626"
  activeFocusOnTab: enabled
  Accessible.role: toggle ? Accessible.CheckBox : Accessible.ComboBox
  Accessible.name: title + ", " + value
  Accessible.checked: checked
  Accessible.onPressAction: activate()
  function activate() { if (toggle) toggled(!checked); else clicked(); }
  Keys.onReturnPressed: activate()
  Keys.onSpacePressed: activate()
  Text {
    x: 20; anchors.verticalCenter: parent.verticalCenter
    text: root.title; color: "#b3b3b3"
    font.family: Shell.Theme.fontFamily; font.pixelSize: 15
  }
  Text {
    anchors.right: parent.right; anchors.rightMargin: 20; anchors.verticalCenter: parent.verticalCenter
    visible: !root.toggle
    text: root.value; color: "#b3b3b3"
    font.family: Shell.Theme.fontFamily; font.pixelSize: 15
  }
  HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
  TapHandler { enabled: !root.toggle; onTapped: root.clicked() }
  Shell.Toggle {
    objectName: "fieldToggle"
    anchors.right: parent.right; anchors.rightMargin: 20; anchors.verticalCenter: parent.verticalCenter
    visible: root.toggle; checked: root.checked
    onToggled: checked => root.toggled(checked)
  }
}
