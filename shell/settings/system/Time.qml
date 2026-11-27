pragma ComponentBehavior: Bound
import QtQuick
import "." as System
import ".." as Settings
import "../.." as Shell

Settings.Modal {
  id: root
  objectName: "timePanel"
  title: "Time"; closeLabel: "Back to System"; bodyTop: 92
  contentHeight: fields.height + 30
  onBackRequested: Settings.State.back()
  Keys.onEscapePressed: Settings.State.back()
  Column {
    id: fields
    x: 30; width: root.width - 60; spacing: 8
    Settings.Field {
      objectName: "timeTimezone"
      width: parent.width; navigation: true
      title: "Timezone"; value: System.State.timezoneLabel + " – " + System.State.timezoneCity
      onClicked: Settings.State.openPage("timezone")
    }
    Rectangle {
      width: fields.width; height: 51; radius: 12
      color: Shell.Theme.colors.settingsRow
      Text {
        x: 20; anchors.verticalCenter: parent.verticalCenter
        text: "Time format"; color: Shell.Theme.colors.text; opacity: 0.7
        font.family: Shell.Theme.fontFamily; font.pixelSize: 15
      }
      Settings.Switcher {
        objectName: "timeFormat"
        anchors.right: parent.right; anchors.rightMargin: 7; anchors.verticalCenter: parent.verticalCenter
        framed: false; radius: 6
        model: [{key: "12", label: "12 Hour", width: 80}, {key: "24", label: "24 Hour", width: 84}]
        current: System.DateTime.timeFormat
        onSelected: key => System.DateTime.setTimeFormat(key)
      }
    }
  }
}
