import Pond.Localization
import QtQuick
import "." as System
import ".." as Settings
import "../.." as Shell

Settings.Modal {
  id: root
  objectName: "systemPanel"
  title: qsTrId("pond.system"); bodyTop: 92
  contentHeight: fields.height + 30
  onBackRequested: Settings.State.back()
  Keys.onEscapePressed: Settings.State.back()
  Column {
    id: fields
    x: 30; width: root.width - 60; spacing: 8
    Settings.Field {
      objectName: "systemMouse"
      width: parent.width; navigation: true
      title: qsTrId("pond.mouse_sensitivity"); value: Math.round(System.State.mouse.speed * 100) + "%"
      onClicked: Settings.State.openPage("mouse")
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
      title: qsTrId("pond.keyboard_language"); value: System.State.languageNames.join(", ")
      onClicked: Settings.State.openPage("keyboard")
    }
    Settings.Field {
      objectName: "systemInterfaceLanguage"
      width: parent.width; navigation: true
      title: qsTrId("settings.interface_language")
      value: Localization.preference === "system" ? qsTrId("settings.follow_system") : Localization.availableLanguages.find(option => option.id === Localization.preference)?.label || ""
      onClicked: Settings.State.openPage("interface-language")
    }
    Settings.Field {
      objectName: "systemTimezone"
      width: parent.width; navigation: true
      title: qsTrId("pond.timezone"); value: System.State.timezoneLabel
      onClicked: Settings.State.openPage("timezone")
    }
    Text {
      width: parent.width; visible: !!System.State.error
      text: System.State.error; color: "#ffb4ab"; wrapMode: Text.Wrap
      font.family: Shell.Theme.fontFamily; font.pixelSize: 13
    }
  }
}
