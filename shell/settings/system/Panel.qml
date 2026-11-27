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
      title: "Mouse sensitivity"; value: Math.round(System.State.pointers.mouse.speed * 100) + "%"
      onClicked: Settings.State.openPage("mouse")
    }
    Settings.Field {
      objectName: "systemKeybinds"
      width: parent.width; navigation: true
      title: "Keybinds"
      onClicked: Settings.State.openPage("keybinds")
    }
    Settings.Field {
      objectName: "systemLock"
      width: parent.width; navigation: true
      title: "Lock & sleep"; value: System.Idle.label(System.Idle.current.lock)
      onClicked: Settings.State.openPage("lock")
    }
    Settings.Field {
      objectName: "systemKeyboard"
      width: parent.width; navigation: true
      title: "Keyboard language"; value: System.State.languageNames.join(", ")
      onClicked: Settings.State.openPage("keyboard")
    }
    Settings.Field {
      objectName: "systemTime"
      width: parent.width; navigation: true
      title: "Time"
      value: [System.State.timezoneCity, System.DateTime.timeFormat + "-hour"].filter(Boolean).join(", ")
      onClicked: Settings.State.openPage("time")
    }
    Text {
      width: parent.width; visible: !!System.State.error
      text: System.State.error; color: "#ffb4ab"; wrapMode: Text.Wrap
      font.family: Shell.Theme.fontFamily; font.pixelSize: 13
    }
  }
}
