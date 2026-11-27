import QtQuick
import "../.." as Shell

Rectangle {
  id: root
  property string placeholder
  property alias input: input
  signal accepted
  objectName: "systemSearch"
  x: 30; y: 82; width: parent.width - 60; height: 51; radius: 12
  color: input.activeFocus && !clearHover.hovered ? Shell.PanelStyle.controlHover : Shell.PanelStyle.controlFill
  HoverHandler { cursorShape: Qt.IBeamCursor }
  TapHandler { onTapped: input.forceActiveFocus() }
  Text {
    x: 20; anchors.verticalCenter: parent.verticalCenter
    visible: !input.text; text: root.placeholder
    color: Shell.Theme.colors.text; opacity: 0.2
    font.family: Shell.Theme.fontFamily; font.pixelSize: 15
  }
  TextInput {
    id: input
    x: 20; width: parent.width - 76; anchors.verticalCenter: parent.verticalCenter
    clip: true; color: Shell.Theme.colors.text
    selectionColor: Shell.PanelStyle.accentText; selectedTextColor: Shell.Theme.colors.text
    font.family: Shell.Theme.fontFamily; font.pixelSize: 15
    Accessible.role: Accessible.EditableText
    Accessible.name: root.placeholder
    cursorDelegate: Rectangle {
      id: caret
      width: 1; color: Shell.PanelStyle.accent
      Timer {
        running: input.cursorVisible; repeat: true
        interval: Qt.styleHints.cursorFlashTime / 2
        onRunningChanged: caret.opacity = 1
        onTriggered: caret.opacity = 1 - caret.opacity
      }
    }
    onAccepted: root.accepted()
  }
  Image {
    x: parent.width - 36; anchors.verticalCenter: parent.verticalCenter
    width: 20; height: 20; sourceSize: Qt.size(40, 40)
    visible: !input.text
    source: Qt.resolvedUrl("../../assets/search.svg")
  }
  Rectangle {
    objectName: "systemSearchClear"
    x: parent.width - 46; anchors.verticalCenter: parent.verticalCenter
    width: 40; height: 40; radius: 4
    visible: !!input.text
    color: clearHover.hovered ? Shell.PanelStyle.rowHover : "transparent"
    Accessible.role: Accessible.Button
    Accessible.name: "Clear search"
    Accessible.onPressAction: input.clear()
    Image {
      anchors.centerIn: parent
      width: 20; height: 20; sourceSize: Qt.size(40, 40)
      source: Qt.resolvedUrl("../../assets/wifi/close.svg")
    }
    HoverHandler { id: clearHover; cursorShape: Qt.PointingHandCursor }
    TapHandler { onTapped: { input.clear(); input.forceActiveFocus(); } }
  }
}
