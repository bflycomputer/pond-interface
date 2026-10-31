pragma ComponentBehavior: Bound
import QtQuick
import "." as System
import ".." as Settings
import "../.." as Shell

Settings.Modal {
  id: root
  objectName: "mousePanel"
  title: "Mouse sensitivity"; closeLabel: "Back to System"; bodyTop: 92
  contentHeight: fields.height + 30
  onBackRequested: Settings.State.back()
  Keys.onEscapePressed: Settings.State.back()
  Column {
    id: fields
    x: 30; width: root.width - 60; spacing: 6
    Repeater {
      model: [{key: "speed", title: "Mouse sensitivity", to: 1}, {key: "scroll", title: "Scrolling sensitivity", to: 2}]
      delegate: Rectangle {
        id: field
        required property var modelData
        width: fields.width; height: 107; radius: 12
        color: slider.visualFocus ? "#303030" : "#262626"
        Text {
          x: 20; y: (51 - height) / 2
          text: field.modelData.title; color: "#b3b3b3"
          font.family: Shell.Theme.fontFamily; font.pixelSize: 15
        }
        Text {
          anchors.right: parent.right; anchors.rightMargin: 20; y: (51 - height) / 2
          text: Math.round(slider.value * 100) + "%"; color: "#b3b3b3"
          font.family: Shell.Theme.fontFamily; font.pixelSize: 15
        }
        Shell.Slider {
          id: slider
          objectName: "mouse" + field.modelData.key
          x: 20; y: 55; width: field.width - 40
          to: field.modelData.to
          externalValue: System.State.mouse[field.modelData.key]
          valueText: Math.round(value * 100)
          ticks: 11
          focusPolicy: Qt.StrongFocus
          Accessible.name: field.modelData.title
          onMoved: System.State.setMouse(field.modelData.key, value)
        }
      }
    }
    Settings.Field {
      objectName: "mouseAcceleration"
      width: parent.width; toggle: true
      title: "Pointer acceleration"; checked: System.State.mouse.acceleration
      onToggled: checked => System.State.setMouse("acceleration", checked)
    }
    Text {
      width: parent.width; visible: !!System.State.error
      text: System.State.error; color: "#ffb4ab"; wrapMode: Text.Wrap
      font.family: Shell.Theme.fontFamily; font.pixelSize: 13
    }
  }
}
