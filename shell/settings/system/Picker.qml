pragma ComponentBehavior: Bound
import QtQuick
import ".." as Settings
import "../.." as Shell

Settings.Modal {
  id: root
  property var options: []
  property var selected: []
  property bool multiple: false
  property string placeholder
  signal picked(string id)
  readonly property string query: search.input.text.trim().toLowerCase()
  readonly property var rows: {
    const pinned = selected.map(id => options.find(option => option.id === id)).filter(Boolean);
    const ordered = pinned.concat(options.filter(option => selected.indexOf(option.id) < 0));
    return query ? ordered.filter(option => (option.search || option.label).toLowerCase().includes(query)) : ordered;
  }
  implicitHeight: Math.min(460, availableHeight)
  bodyTop: 143
  roundedContent: true
  onBackRequested: Settings.State.back()
  Keys.onEscapePressed: { if (search.input.text) search.input.clear(); else Settings.State.back(); }

  function choose(id) {
    picked(id);
    search.input.clear();
    search.input.forceActiveFocus();
  }

  ListView {
    id: list
    objectName: "systemOptions"
    x: 16; width: root.width - 32; height: root.scrollItem.height
    bottomMargin: 16
    boundsBehavior: Flickable.StopAtBounds
    model: root.rows
    Shell.ScrollWheel { view: list }
    delegate: Rectangle {
      id: row
      required property var modelData
      required property int index
      readonly property bool chosen: root.selected.indexOf(modelData.id) >= 0
      readonly property bool highlighted: hover.hovered || (!!root.query && index === 0)
      width: list.width; height: 50; radius: 12
      color: highlighted ? Shell.PanelStyle.rowHover : "transparent"
      Accessible.role: root.multiple ? Accessible.CheckBox : Accessible.RadioButton
      Accessible.name: modelData.label
      Accessible.checked: chosen
      Accessible.onPressAction: root.choose(modelData.id)
      Text {
        id: offset
        x: 20; anchors.verticalCenter: parent.verticalCenter
        visible: !!text; text: row.modelData.offset || ""
        color: Shell.Theme.colors.text; opacity: 0.4
        font.family: "JetBrains Mono"; font.pixelSize: 14
      }
      Text {
        x: offset.visible ? offset.x + offset.width + 12 : 20
        width: parent.width - x - 64
        anchors.verticalCenter: parent.verticalCenter
        text: row.modelData.label; elide: Text.ElideRight
        color: Shell.Theme.colors.text; opacity: 0.7
        font.family: Shell.Theme.fontFamily; font.pixelSize: 15
      }
      Rectangle {
        visible: root.multiple
        x: parent.width - 44; anchors.verticalCenter: parent.verticalCenter
        width: 24; height: 24; radius: 6
        color: row.highlighted ? Shell.PanelStyle.controlHover : Shell.PanelStyle.controlFill
      }
      Image {
        visible: row.chosen
        x: parent.width - (root.multiple ? 42 : 40); anchors.verticalCenter: parent.verticalCenter
        width: 20; height: 20; sourceSize: Qt.size(40, 40)
        source: Qt.resolvedUrl("../../assets/installs/check.svg")
      }
      HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
      TapHandler { onTapped: root.choose(row.modelData.id) }
    }
  }

  overlay: [
    Search {
      id: search
      placeholder: root.placeholder
      onAccepted: if (root.query && root.rows.length) root.choose(root.rows[0].id)
    },
    Rectangle {
      objectName: "keyboardShortcut"
      visible: root.multiple
      x: root.width - 106; y: 21; width: 76; height: 40; radius: 8
      color: shortcutHover.hovered ? Shell.PanelStyle.rowHover : "transparent"
      border.width: shortcutHover.hovered ? 0 : 1; border.color: Shell.PanelStyle.outline
      Accessible.role: Accessible.StaticText
      Accessible.name: "Shortcut: Super+K switches between languages"
      Text {
        anchors.centerIn: parent
        text: "Shortcut"; color: Shell.Theme.colors.text; opacity: shortcutHover.hovered ? 1 : 0.5
        font.family: Shell.Theme.fontFamily; font.weight: Font.DemiBold
        font.pixelSize: 10; font.letterSpacing: 0.1
      }
      HoverHandler { id: shortcutHover }
    },
    Item {
      objectName: "keyboardShortcutTip"
      x: root.width + 10; width: 160; height: 142
      visible: shortcutHover.hovered
      Item {
        anchors { fill: parent; margins: -90; bottomMargin: -180 }
        layer.enabled: true
        layer.format: ShaderEffectSource.RGBA16F
        Shell.Shadow {
          anchors { fill: parent; margins: 90; bottomMargin: 180 }
          cornerRadius: 24
          shadows: Shell.PanelStyle.controlShadows.map(s => Object.assign({}, s, { blur: s.blur * 2.4 }))
        }
      }
      Rectangle {
        anchors.fill: parent; radius: 24
        color: Settings.Style.card
        Text {
          x: 20; y: 15; width: 120
          text: "Switch between languages"; color: Shell.Theme.colors.text
          wrapMode: Text.WordWrap; lineHeight: 21; lineHeightMode: Text.FixedHeight
          font.family: Shell.Theme.fontFamily; font.weight: Font.Medium; font.pixelSize: 15
        }
        Row {
          x: 20; y: 82; spacing: 6
          Repeater {
            model: ["Mod", "K"]
            delegate: Key { required property string modelData; name: modelData }
          }
        }
      }
    }
  ]
}
