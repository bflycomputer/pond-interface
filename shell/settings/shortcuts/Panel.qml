pragma ComponentBehavior: Bound

import QtQuick
import ".." as Settings
import "." as Shortcuts
import "../.." as Shell

Settings.Modal {
  id: root
  objectName: "shortcutsPanel"
  title: "Keyboard shortcuts"
  bodyTop: 143
  roundedContent: true
  contentHeight: list.contentHeight + 16
  onBackRequested: Settings.State.back()
  Keys.onEscapePressed: { if (search.text) search.clear(); else Settings.State.back(); }
  Keys.onDownPressed: root.moveFocus(1)
  Keys.onUpPressed: root.moveFocus(-1)

  readonly property string query: search.text.trim().toLowerCase()
  // Exactly one highlight is visible at a time: the keyboard's when arrows
  // are used, the cursor's otherwise. Hover keeps the two in sync so the
  // states hand over instead of stacking.
  property string interactMode: "cursor"
  readonly property real barSize: 58

  readonly property var rows: {
    const custom = Shortcuts.State.binds.filter(bind => bind.custom);
    const stock = Shortcuts.State.binds.filter(bind => !bind.custom);
    const ordered = custom.concat(stock).map(bind => {
      return {
        bind: bind, label: Shortcuts.State.label(bind),
        chips: Shortcuts.State.chips(bind.key)
      };
    });
    return query ? ordered.filter(row =>
        (row.label + " " + row.bind.key + " " + row.bind.action).toLowerCase().includes(query)) : ordered;
  }

  function moveFocus(delta) {
    if (list.count === 0) return;
    root.interactMode = "keyboard";
    list.currentIndex = Math.max(0, Math.min(list.count - 1, list.currentIndex + delta));
    list.positionViewAtIndex(list.currentIndex, ListView.Contain);
  }

  // Grow the list upward as the focus walker moves back to the top so the
  // first row keeps its position above the search bar.
  onInteractModeChanged: if (interactMode === "cursor") list.currentIndex = -1

  ListView {
    id: list
    objectName: "shortcutsList"
    x: 30; width: root.width - 60
    y: 0
    height: root.scrollItem.height - root.barSize
    bottomMargin: 16
    boundsBehavior: Flickable.StopAtBounds
    model: root.rows
    spacing: 8
    clip: true
    currentIndex: -1
    Shell.ScrollWheel { view: list }

    delegate: Rectangle {
      id: row
      required property var modelData
      required property int index
      readonly property bool editAccess: modelData.bind.custom
      readonly property bool highlighted: root.interactMode === "keyboard"
          ? list.currentIndex === index : hover.hovered

      width: list.width; height: 50; radius: 12
      color: highlighted ? "#262626" : "transparent"
      Accessible.role: editAccess ? Accessible.Button : Accessible.StaticText
      Accessible.name: modelData.label + ", " + modelData.bind.key
      Accessible.onPressAction: if (row.editAccess) Shortcuts.State.requestEditor(modelData.bind)

      Text {
        x: 20; width: 300
        anchors.verticalCenter: parent.verticalCenter
        text: row.modelData.label; elide: Text.ElideRight
        color: "white"; opacity: row.editAccess ? 1 : 0.7
        font.family: Shell.Theme.fontFamily; font.pixelSize: 15
      }
      Row {
        anchors.right: parent.right
        anchors.rightMargin: row.editAccess ? 36 : 12
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8
        Shortcuts.Keys { chord: row.modelData.bind.key; size: 24 }
        Image {
          visible: row.editAccess
          anchors.verticalCenter: parent.verticalCenter
          width: 16; height: 16; sourceSize: Qt.size(32, 32)
          source: Qt.resolvedUrl("../../assets/appearance/chevron.svg")
          rotation: -90
        }
      }

      HoverHandler {
        id: hover; cursorShape: Qt.PointingHandCursor
        onHoveredChanged: if (hovered) {
          root.interactMode = "cursor";
          list.currentIndex = row.index;
        }
      }
      TapHandler {
        onTapped: {
          root.interactMode = "cursor";
          list.currentIndex = row.index;
          if (row.editAccess) Shortcuts.State.requestEditor(modelData.bind);
        }
      }
    }
  }

  Text {
    // Empty-list message sits where rows would; only shows for narrow
    // searches once the custom list is shorter than the viewport.
    objectName: "shortcutsEmpty"
    x: 30; y: list.y; width: root.width - 60
    visible: list.count === 0
    text: root.query ? "Nothing matches \"" + root.query + "\"" : "No shortcuts found"
    color: "white"; opacity: 0.3
    horizontalAlignment: Text.AlignHCenter
    font.family: Shell.Theme.fontFamily; font.pixelSize: 14
  }

  overlay: [
    Rectangle {
      objectName: "shortcutsSearch"
      x: 30; y: 82; width: root.width - 60; height: 51; radius: 12
      color: search.activeFocus ? "#303030" : "#262626"
      Text {
        x: 20; anchors.verticalCenter: parent.verticalCenter
        visible: !search.text; text: "Search shortcuts"
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
        Accessible.name: "Search shortcuts"
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
        Keys.onDownPressed: root.moveFocus(1)
        Keys.onUpPressed: root.moveFocus(-1)
        Keys.onEscapePressed: root.search.clear()
      }
      Image {
        x: parent.width - 36; anchors.verticalCenter: parent.verticalCenter
        width: 20; height: 20; sourceSize: Qt.size(40, 40)
        visible: !search.text
        source: Qt.resolvedUrl("../../assets/search.svg")
      }
      Rectangle {
        objectName: "shortcutsSearchClear"
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
      // Pinned add button: hangs under the list so every row stays visible
      // while scrolling and shortcuts never hide it.
      objectName: "shortcutsAddPinned"
      x: 30
      y: root.height - root.barSize
      width: root.width - 60
      height: 50
      radius: 12
      color: addHover.hovered ? "#262626" : "transparent"
      border.width: 1
      border.color: "#303030"
      Accessible.role: Accessible.Button
      Accessible.name: "Add shortcut"
      Accessible.onPressAction: Shortcuts.State.newShortcut()

      Text {
        x: 20; anchors.verticalCenter: parent.verticalCenter
        text: "+"; color: "white"; opacity: 0.7
        font.family: Shell.Theme.fontFamily; font.pixelSize: 17; font.weight: Font.Bold
      }
      Text {
        x: 44; anchors.verticalCenter: parent.verticalCenter
        text: "Add shortcut"; color: "white"; opacity: 0.7
        font.family: Shell.Theme.fontFamily; font.pixelSize: 15
      }
      HoverHandler { id: addHover; cursorShape: Qt.PointingHandCursor }
      TapHandler { onTapped: Shortcuts.State.newShortcut() }
    },
    Rectangle {
      objectName: "shortcutsOverlayError"
      visible: Shortcuts.State.error !== ""
      x: 30; y: 30; width: root.width - 60; height: 30
      color: "transparent"
      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: Shortcuts.State.error; color: "#ffb4ab"; elide: Text.ElideRight
        font.family: Shell.Theme.fontFamily; font.pixelSize: 12
      }
      MouseArea { anchors.fill: parent; onClicked: Shortcuts.State.error = "" }
    },
    Rectangle {
      // Renders in the header, next to the title: how many are personal.
      objectName: "shortcutsCount"
      x: root.width - 130; y: 30
      visible: root.width > 500 && Shortcuts.State.binds.some(bind => bind.custom)
      width: 100; height: 22; radius: 11
      color: "transparent"
      border.width: 1; border.color: "#4a4a4a"
      Text {
        anchors.centerIn: parent
        text: Shortcuts.State.binds.filter(bind => bind.custom).length + " personal"
        color: "white"; opacity: 0.5
        font.family: Shell.Theme.fontFamily; font.pixelSize: 10
      }
    }
  ]
}
