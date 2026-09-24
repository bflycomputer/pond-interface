pragma ComponentBehavior: Bound
import QtQuick
import "." as Display
import ".." as Settings
import "../.." as Shell
import "Geometry.js" as Geometry

Settings.Modal {
  id: root
  objectName: "displayPanel"
  title: "Display"; closeLabel: "Back to Appearance"; bodyTop: 77
  contentHeight: fields.y + fields.height + 30
  titleOpacity: dropdownField ? 0.3 : 1
  property string dropdownField: ""
  property real dropdownCenter: 0
  readonly property var monitor: Display.State.selected
  readonly property var rows: {
    const m = monitor;
    if (!m) return [];
    const result = [];
    if (m.scales.length > 1) result.push({key:"scale",title:"Scale",value:m.scale + "x",current:String(m.scale),options:m.scales.map(s=>({label:s+"x",value:String(s)}))});
    if (m.resolutions.some(r=>r.value!==m.width+"x"+m.height)) result.push({key:"resolution",title:"Resolution",value:m.width+" x "+m.height,current:m.width+"x"+m.height,options:m.resolutions});
    if (m.rates.some(r=>r.value!==String(m.refresh))) result.push({key:"refresh",title:"Refresh rate",value:(m.refresh/1000).toFixed(3).replace(/\.?0+$/, "")+" Hz",current:String(m.refresh),options:m.rates});
    if (m.vrrSupported) result.push({key:"vrr",title:"Adaptive sync",value:m.vrrEnabled?"On":"Off",current:"",options:[]});
    return result;
  }
  readonly property var dropdownRow: rows.find(r=>r.key===dropdownField) || null
  onBackRequested: { if (dropdownField) closeDropdown(); else Settings.State.back(); }
  Keys.onEscapePressed: { if (dropdownField) closeDropdown(); else Settings.State.back(); }
  Connections {
    target: Display.State
    function onMonitorsChanged() { root.closeDropdown(); }
    function onSelectedNameChanged() { root.closeDropdown(); }
  }
  function closeDropdown() { dropdownField = ""; forceActiveFocus(); }
  function openDropdown(row, field) {
    const p = field.mapToItem(root,0,field.height/2);
    dropdownCenter = p.y;
    dropdownField = row.key;
    Qt.callLater(() => { const menu = dropdownLoader.item as Display.Dropdown; if (menu) menu.forceActiveFocus(); });
  }
  Rectangle {
    id: preview
    objectName: "displayPreview"
    x: 30; width: root.width - 60; height: 281; radius: 16
    color: "transparent"; border.width: 1; border.color: "#303030"
    opacity: root.dropdownField ? 0.3 : 1
    enabled: !root.dropdownField && !Display.State.busy
    Item {
      id: previewArea
      width: parent.width; height: Display.State.monitors.length > 1 ? 233 : parent.height
      readonly property var layout: Geometry.fit(Display.State.geometry,width,height,48,286)
      readonly property real inset: Display.State.monitors.length > 1 ? 4 : 0
      Repeater {
        model: Display.State.monitors
        delegate: Display.Monitor {
          id: monitorTile
          required property var modelData
          objectName: "displayMonitor" + modelData.name
          x: previewArea.layout.x + modelData.logical.x * previewArea.layout.scale + previewArea.inset
          y: previewArea.layout.y + modelData.logical.y * previewArea.layout.scale + previewArea.inset
          width: Math.max(20,modelData.logical.width * previewArea.layout.scale - 2 * previewArea.inset)
          height: Math.max(20,modelData.logical.height * previewArea.layout.scale - 2 * previewArea.inset)
          label: modelData.label
          selected: Display.State.monitors.length > 1 && modelData.name === Display.State.selectedName
          hovered: tileHover.hovered
          activeFocusOnTab: true
          Accessible.role: Accessible.RadioButton; Accessible.name: label + ", " + modelData.name
          Accessible.checked: selected
          Accessible.onPressAction: Display.State.select(modelData.name)
          Keys.onSpacePressed: Display.State.select(modelData.name)
          Keys.onReturnPressed: Display.State.select(modelData.name)
          HoverHandler { id: tileHover; cursorShape: Qt.PointingHandCursor }
          TapHandler { onTapped: Display.State.select(monitorTile.modelData.name) }
        }
      }
      Text {
        anchors.centerIn: parent; visible: !Display.State.monitors.length
        text: Display.State.loaded ? "No connected displays" : "Loading displays…"
        font.family: Shell.Theme.fontFamily; font.pixelSize: 15; color: "#b3b3b3"
      }
    }
    Rectangle {
      objectName: "arrangeDisplays"
      x: 8; y: 233; width: 97; height: 40; radius: 12
      visible: Display.State.monitors.length > 1
      color: arrangeHover.hovered || activeFocus ? "#262626" : "transparent"
      activeFocusOnTab: visible && enabled
      Accessible.role: Accessible.Button; Accessible.name: "Arrange displays"
      Accessible.onPressAction: Settings.State.openPage("arrange")
      Keys.onReturnPressed: Settings.State.openPage("arrange")
      Keys.onSpacePressed: Settings.State.openPage("arrange")
      Text { anchors.centerIn: parent; text: "Arrange"; color: "#b3b3b3"; font.family: Shell.Theme.fontFamily; font.pixelSize: 15 }
      HoverHandler { id: arrangeHover; cursorShape: Qt.PointingHandCursor }
      TapHandler { onTapped: Settings.State.openPage("arrange") }
    }
  }
  Column {
    id: fields
    x: 30; y: 292; width: root.width - 60; spacing: 8
    Repeater {
      model: root.rows.length
      delegate: Display.Field {
        id: field
        required property int index
        readonly property var modelData: root.rows[index] || {key: "", title: "", value: ""}
        objectName: "displayField" + modelData.key
        width: fields.width
        title: modelData.title; value: modelData.value
        toggle: modelData.key === "vrr"; checked: root.monitor ? root.monitor.vrrEnabled : false
        highlighted: root.dropdownField === modelData.key
        opacity: root.dropdownField && !highlighted ? 0.3 : 1
        enabled: !Display.State.busy && !root.dropdownField
        onClicked: root.openDropdown(modelData, field)
        onToggled: checked => Display.State.change("vrr",checked ? "on" : "off")
      }
    }
    Text {
      width: parent.width; visible: !!Display.State.error
      text: Display.State.error; color: "#ffb4ab"; wrapMode: Text.Wrap
      font.family: Shell.Theme.fontFamily; font.pixelSize: 13
    }
  }
  overlay: [
    MouseArea {
      anchors.fill: parent; visible: !!root.dropdownField
      onClicked: root.closeDropdown()
      onWheel: event => { event.accepted = true; }
    },
    Loader {
      id: dropdownLoader
      objectName: "displayDropdownLoader"
      active: !!root.dropdownRow
      x: root.width - width - 38
      y: Math.max(60,Math.min(root.dropdownCenter - height/2,root.height-height-24))
      sourceComponent: Component {
        Display.Dropdown {
          objectName: "displayDropdown"
          maximumHeight: Math.max(56,root.height-84)
          width: root.dropdownField === "scale" ? 226 : 276
          options: root.dropdownRow ? root.dropdownRow.options : []
          currentValue: root.dropdownRow ? root.dropdownRow.current : ""
          onDismissed: root.closeDropdown()
          onSelected: value => { const field = root.dropdownField; root.closeDropdown(); Display.State.change(field,value); }
        }
      }
    }
  ]
}
