pragma ComponentBehavior: Bound
import QtQuick
import "." as System
import ".." as Settings
import "../../battery" as Battery
import "../.." as Shell

Settings.Modal {
  id: root
  objectName: "lockPanel"
  title: "Lock & sleep"; closeLabel: "Back to System"; bodyTop: 92
  contentHeight: fields.height + 30
  property string power: System.Idle.source
  property string dropdownField: ""
  property real dropdownCenter: 0
  readonly property var rows: [
    {key: "lock", title: "Lock screen after inactivity for"},
    {key: "display", title: "Turn display off after inactivity for"},
    {key: "sleep", title: "Sleep after inactivity"}
  ]
  onBackRequested: { if (dropdownField) closeDropdown(); else Settings.State.back(); }
  Keys.onEscapePressed: { if (dropdownField) closeDropdown(); else Settings.State.back(); }
  function closeDropdown() { dropdownField = ""; forceActiveFocus(); }
  function openDropdown(key, field) {
    dropdownCenter = field.mapToItem(root, 0, field.height / 2).y;
    dropdownField = key;
    Qt.callLater(() => { const menu = dropdownLoader.item as Settings.Dropdown; if (menu) menu.forceActiveFocus(); });
  }
  Column {
    id: fields
    x: 30; width: root.width - 60; spacing: 6
    Repeater {
      model: root.rows
      delegate: Settings.Field {
        id: field
        required property var modelData
        required property int index
        objectName: "lockField" + modelData.key
        width: fields.width; step: index + 1
        title: modelData.title
        value: System.Idle.label(System.Idle.timeouts[root.power][modelData.key])
        highlighted: root.dropdownField === modelData.key
        opacity: root.dropdownField && !highlighted ? 0.3 : 1
        enabled: !root.dropdownField
        onClicked: root.openDropdown(modelData.key, field)
      }
    }
  }
  overlay: [
    Settings.Switcher {
      objectName: "lockPower"
      visible: Battery.State.present
      x: root.width - width - 30; y: 20
      opacity: root.dropdownField ? 0.3 : 1
      enabled: !root.dropdownField
      model: [{key: "pluggedIn", label: "Plugged in", width: 80}, {key: "battery", label: "On Battery", width: 84}]
      current: root.power
      onSelected: key => root.power = key
    },
    MouseArea {
      anchors.fill: parent; visible: !!root.dropdownField
      onClicked: root.closeDropdown()
      onWheel: event => { event.accepted = true; }
    },
    Loader {
      id: dropdownLoader
      active: !!root.dropdownField
      x: root.width - width - 38
      y: root.dropdownCenter - height / 2
      sourceComponent: Component {
        Settings.Dropdown {
          objectName: "lockDropdown"
          width: 181
          options: System.Idle.options
          currentValue: String(System.Idle.timeouts[root.power][root.dropdownField])
          onDismissed: root.closeDropdown()
          onSelected: value => { const key = root.dropdownField; root.closeDropdown(); System.Idle.set(root.power, key, Number(value)); }
        }
      }
    }
  ]
}
