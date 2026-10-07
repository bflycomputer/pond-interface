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
  readonly property string query: search.text.trim().toLowerCase()
  readonly property var rows: {
    const pinned = selected.map(id => options.find(option => option.id === id)).filter(Boolean);
    const ordered = pinned.concat(options.filter(option => selected.indexOf(option.id) < 0));
    return query ? ordered.filter(option => (option.search || option.label).toLowerCase().includes(query)) : ordered;
  }
  implicitHeight: Math.min(460, availableHeight)
  bodyTop: 143
  roundedContent: true
  onBackRequested: Settings.State.back()
  Keys.onEscapePressed: { if (search.text) search.clear(); else Settings.State.back(); }

  function choose(id) {
    picked(id);
    search.clear();
    search.forceActiveFocus();
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
      color: highlighted ? "#262626" : "transparent"
      Accessible.role: root.multiple ? Accessible.CheckBox : Accessible.RadioButton
      Accessible.name: modelData.label
      Accessible.checked: chosen
      Accessible.onPressAction: root.choose(modelData.id)
      Text {
        id: offset
        x: 20; anchors.verticalCenter: parent.verticalCenter
        visible: !!text; text: row.modelData.offset || ""
        color: "white"; opacity: 0.4
        font.family: "JetBrains Mono"; font.pixelSize: 14
      }
      Text {
        x: offset.visible ? offset.x + offset.width + 12 : 20
        width: parent.width - x - 64
        anchors.verticalCenter: parent.verticalCenter
        text: row.modelData.label; elide: Text.ElideRight
        color: "white"; opacity: 0.7
        font.family: Shell.Theme.fontFamily; font.pixelSize: 15
      }
      Rectangle {
        visible: root.multiple
        x: parent.width - 44; anchors.verticalCenter: parent.verticalCenter
        width: 24; height: 24; radius: 6
        color: row.highlighted ? "#303030" : "#262626"
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
    Rectangle {
      objectName: "systemSearch"
      x: 30; y: 82; width: root.width - 60; height: 51; radius: 12
      color: search.activeFocus && !clearHover.hovered ? "#303030" : "#262626"
      HoverHandler { cursorShape: Qt.IBeamCursor }
      TapHandler { onTapped: search.forceActiveFocus() }
      Text {
        x: 20; anchors.verticalCenter: parent.verticalCenter
        visible: !search.text; text: root.placeholder
        color: "white"; opacity: 0.2
        font.family: Shell.Theme.fontFamily; font.pixelSize: 15
      }
      TextInput {
        id: search
        x: 20; width: parent.width - 76; anchors.verticalCenter: parent.verticalCenter
        clip: true; color: "white"
        selectionColor: Shell.PanelStyle.accentText; selectedTextColor: "white"
        font.family: Shell.Theme.fontFamily; font.pixelSize: 15
        Accessible.role: Accessible.EditableText
        Accessible.name: root.placeholder
        cursorDelegate: Rectangle {
          id: caret
          width: 1; color: Shell.PanelStyle.accent
          Timer {
            running: search.cursorVisible; repeat: true
            interval: Qt.styleHints.cursorFlashTime / 2
            onRunningChanged: caret.opacity = 1
            onTriggered: caret.opacity = 1 - caret.opacity
          }
        }
        onAccepted: if (root.query && root.rows.length) root.choose(root.rows[0].id)
      }
      Image {
        x: parent.width - 36; anchors.verticalCenter: parent.verticalCenter
        width: 20; height: 20; sourceSize: Qt.size(40, 40)
        visible: !search.text
        source: Qt.resolvedUrl("../../assets/search.svg")
      }
      Rectangle {
        objectName: "systemSearchClear"
        x: parent.width - 46; anchors.verticalCenter: parent.verticalCenter
        width: 40; height: 40; radius: 4
        visible: !!search.text
        color: clearHover.hovered ? "#303030" : "transparent"
        Accessible.role: Accessible.Button
        Accessible.name: "Clear search"
        Accessible.onPressAction: search.clear()
        Image {
          anchors.centerIn: parent
          width: 20; height: 20; sourceSize: Qt.size(40, 40)
          source: Qt.resolvedUrl("../../assets/wifi/close.svg")
        }
        HoverHandler { id: clearHover; cursorShape: Qt.PointingHandCursor }
        TapHandler { onTapped: { search.clear(); search.forceActiveFocus(); } }
      }
    },
    Rectangle {
      objectName: "keyboardShortcut"
      visible: root.multiple
      x: root.width - 106; y: 21; width: 76; height: 40; radius: 8
      color: shortcutHover.hovered ? "#262626" : "transparent"
      border.width: shortcutHover.hovered ? 0 : 1; border.color: "#303030"
      Accessible.role: Accessible.StaticText
      Accessible.name: "Shortcut: Super+K switches between languages"
      Text {
        anchors.centerIn: parent
        text: "Shortcut"; color: "white"; opacity: shortcutHover.hovered ? 1 : 0.5
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
          text: "Switch between languages"; color: "white"
          wrapMode: Text.WordWrap; lineHeight: 21; lineHeightMode: Text.FixedHeight
          font.family: Shell.Theme.fontFamily; font.weight: Font.Medium; font.pixelSize: 15
        }
        Row {
          x: 20; y: 82; spacing: 6
          Repeater {
            model: ["spr", "k"]
            delegate: Rectangle {
              id: key
              required property string modelData
              width: 40; height: 40; radius: 4
              color: "transparent"; border.color: "#4a4a4a"
              Rectangle {
                anchors.centerIn: parent; width: 32; height: 32; radius: 16
                color: "transparent"; border.color: "#4a4a4a"
              }
              Text {
                anchors.centerIn: parent
                text: key.modelData; color: "white"
                font.family: Shell.Theme.fontFamily
                font.weight: key.modelData === "k" ? Font.Bold : Font.DemiBold
                font.pixelSize: key.modelData === "k" ? 12 : 10
              }
            }
          }
        }
      }
    }
  ]
}
