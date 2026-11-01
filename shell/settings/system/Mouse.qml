pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Templates as T
import "." as System
import ".." as Settings
import "../.." as Shell

Settings.Modal {
  id: root
  objectName: "mousePanel"
  title: "Mouse sensitivity"; closeLabel: "Back to System"; bodyTop: 92
  contentHeight: fields.height + 30
  property string naturalKey: "naturalTouchpad"
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
        color: slider.visualFocus ? Shell.PanelStyle.controlHover : Shell.PanelStyle.controlFill
        Text {
          x: 20; y: (51 - height) / 2
          text: field.modelData.title; color: Qt.rgba(1, 1, 1, 0.7)
          font.family: Shell.Theme.fontFamily; font.pixelSize: 15
        }
        Text {
          anchors.right: parent.right; anchors.rightMargin: 20; y: (51 - height) / 2
          text: Math.round(slider.value * 100) + "%"; color: Qt.rgba(1, 1, 1, 0.7)
          font.family: Shell.Theme.fontFamily; font.pixelSize: 15
        }
        Repeater {
          model: 11
          delegate: Rectangle {
            required property int index
            x: 20 + index * 47.6; y: 83; width: 4; height: 4; radius: 2
            color: "#d9d9d9"; opacity: 0.2
          }
        }
        T.Slider {
          id: slider
          objectName: "mouse" + field.modelData.key
          x: 20; y: 55; width: 480; height: 24
          leftPadding: 2; rightPadding: 2
          to: field.modelData.to; value: System.State.mouse[field.modelData.key]
          Accessible.name: field.modelData.title
          onMoved: System.State.setMouse(field.modelData.key, value)
          background: Rectangle {
            y: 4; width: slider.width; height: 16; radius: 8
            color: Shell.PanelStyle.sliderTrack
            Rectangle {
              x: 1; y: 1; width: slider.leftPadding + slider.visualPosition * slider.availableWidth - 1
              height: 14; radius: 7
              color: "#d9d9d9"
            }
          }
          handle: Rectangle {
            x: slider.leftPadding + slider.visualPosition * slider.availableWidth - width / 2
            width: 24; height: 24; radius: 12
            color: "#e7e7e7"; border.width: 2; border.color: Qt.tint(root.color, field.color)
          }
          HoverHandler { cursorShape: Qt.PointingHandCursor }
        }
      }
    }
    Settings.Field {
      objectName: "mouseAcceleration"
      width: parent.width; toggle: true
      title: "Pointer acceleration"; checked: System.State.mouse.acceleration
      onToggled: checked => System.State.setMouse("acceleration", checked)
    }
    Rectangle {
      width: parent.width; height: 108; radius: 12
      color: Shell.PanelStyle.controlFill
      Text {
        x: 20; y: (51 - height) / 2
        text: "Natural scrolling"; color: Qt.rgba(1, 1, 1, 0.7)
        font.family: Shell.Theme.fontFamily; font.pixelSize: 15
      }
      Settings.Switcher {
        objectName: "mouseNatural"
        x: 20; y: 47; radius: 8
        model: [{key: "naturalTouchpad", label: "Trackpad", width: 80}, {key: "naturalMouse", label: "Mouse", width: 84}]
        current: root.naturalKey
        onSelected: key => root.naturalKey = key
      }
      Shell.Toggle {
        objectName: "mouseNaturalToggle"
        x: parent.width - width - 20; y: 54
        activeFocusOnTab: true
        Accessible.role: Accessible.CheckBox
        Accessible.name: "Natural scrolling"
        Accessible.checked: checked
        Keys.onReturnPressed: toggled(!checked)
        Keys.onSpacePressed: toggled(!checked)
        checked: System.State.mouse[root.naturalKey]
        onToggled: checked => System.State.setMouse(root.naturalKey, checked)
      }
    }
    Text {
      width: parent.width; visible: !!System.State.error
      text: System.State.error; color: "#ffb4ab"; wrapMode: Text.Wrap
      font.family: Shell.Theme.fontFamily; font.pixelSize: 13
    }
  }
}
