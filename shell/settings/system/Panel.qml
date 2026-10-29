import QtQuick
import "." as System
import ".." as Settings
import "../.." as Shell

Settings.Modal {
  id: root
  objectName: "systemPanel"
  title: "System"; bodyTop: 92
  contentHeight: fields.height + 30
  onBackRequested: Settings.State.back()
  Keys.onEscapePressed: Settings.State.back()
  Column {
    id: fields
    x: 30; width: root.width - 60; spacing: 8
    Settings.Field {
      objectName: "systemMouse"
      width: parent.width; navigation: true
      title: "Mouse sensitivity"; value: Math.round(System.State.mouse.speed * 100) + "%"
      onClicked: Settings.State.openPage("mouse")
    }
    Settings.Field {
      objectName: "systemKeyboard"
      width: parent.width; navigation: true
      title: "Keyboard language"; value: System.State.languageNames.join(", ")
      onClicked: Settings.State.openPage("keyboard")
    }
    Settings.Field {
      objectName: "systemShortcuts"
      width: parent.width; navigation: true
      title: "Keyboard shortcuts"; value: "Super + / opens the list"
      onClicked: Settings.State.openPage("shortcuts")
    }
    Settings.Field {
      objectName: "systemTimezone"
      width: parent.width; navigation: true
      title: "Timezone"; value: System.State.timezoneLabel
      onClicked: Settings.State.openPage("timezone")
    }
    Text {
      width: parent.width; visible: !!System.State.error
      text: System.State.error; color: "#ffb4ab"; wrapMode: Text.Wrap
      font.family: Shell.Theme.fontFamily; font.pixelSize: 13
    }
  }
}
