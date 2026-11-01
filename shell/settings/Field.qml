import QtQuick
import ".." as Shell
Rectangle {
  id: root
  property string title
  property string value
  property bool highlighted: false
  property bool toggle: false
  property bool checked: false
  property bool navigation: false
  property int step: 0
  signal clicked
  signal toggled(bool checked)
  width: 520; height: 51; radius: 12
  color: highlighted || hover.hovered || activeFocus ? Shell.PanelStyle.controlHover : Shell.PanelStyle.controlFill
  activeFocusOnTab: enabled
  Accessible.role: toggle ? Accessible.CheckBox : navigation ? Accessible.Button : Accessible.ComboBox
  Accessible.name: title + ", " + value
  Accessible.checked: checked
  Accessible.onPressAction: activate()
  function activate() { if (toggle) toggled(!checked); else clicked(); }
  Keys.onReturnPressed: activate()
  Keys.onSpacePressed: activate()
  Rectangle {
    x: 20; anchors.verticalCenter: parent.verticalCenter
    visible: root.step > 0
    width: 24; height: 24; radius: 12
    color: "transparent"; border.color: "white"; opacity: 0.6
    Text {
      anchors.centerIn: parent
      text: root.step; color: "white"
      font.family: Shell.Theme.plexFontFamily; font.weight: Font.DemiBold
      font.pixelSize: 11; font.letterSpacing: -0.22
    }
  }
  Text {
    id: label
    x: root.step > 0 ? 54 : 20; anchors.verticalCenter: parent.verticalCenter
    text: root.title; color: "white"; opacity: 0.7
    font.family: Shell.Theme.fontFamily; font.pixelSize: 15
  }
  Text {
    anchors.right: parent.right; anchors.rightMargin: root.navigation ? 40 : 20; anchors.verticalCenter: parent.verticalCenter
    width: Math.max(0, parent.width - label.x - label.width - 20 - anchors.rightMargin)
    horizontalAlignment: Text.AlignRight
    elide: Text.ElideRight
    visible: !root.toggle
    text: root.value; color: "white"; opacity: 0.7
    font.family: Shell.Theme.fontFamily; font.pixelSize: 15
  }
  Image {
    anchors.right: parent.right; anchors.rightMargin: 20; anchors.verticalCenter: parent.verticalCenter
    width: 16; height: 16; visible: root.navigation
    source: Qt.resolvedUrl("../assets/appearance/chevron.svg")
    rotation: -90
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
