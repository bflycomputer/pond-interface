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
  // Sized from the unfiltered list and capped at the window, so searching
  // never resizes the card and only the list scrolls, never the body.
  contentHeight: Math.min(entries.length * 58 - 8 + list.bottomMargin + barSize,
      availableHeight - bodyTop)
  onBackRequested: Settings.State.back()
  Keys.onEscapePressed: root.dismiss()
  Keys.onDownPressed: root.moveFocus(1)
  Keys.onUpPressed: root.moveFocus(-1)
  Keys.onReturnPressed: root.activate()
  Keys.onEnterPressed: root.activate()

  readonly property string query: search.text.trim().toLowerCase()
  // Exactly one highlight is visible at a time: the keyboard's when arrows
  // are used, the cursor's otherwise. Hover keeps the two in sync so the
  // states hand over instead of stacking.
  property string interactMode: "cursor"
  // Side margins are 30; the bottom gap matches so the pinned bar reads as
  // part of the card's rhythm.
  readonly property real bottomGap: 24
  readonly property real barSize: 50 + bottomGap

  // Built once per reload; typing only filters.
  readonly property var entries: {
    const binds = Shortcuts.State.binds;
    return binds.filter(bind => bind.custom).concat(binds.filter(bind => !bind.custom)).map(bind => {
      const label = Shortcuts.State.label(bind);
      return {
        bind: bind, label: label,
        text: (label + " " + bind.key + " " + bind.action + " "
            + Shortcuts.State.chipsText(bind)).toLowerCase()
      };
    });
  }
  readonly property int customCount: entries.filter(row => row.bind.custom).length
  readonly property var rows: {
    const words = query.split(/\s+/).filter(word => word !== "");
    if (words.length === 0) return entries;
    // Every word must land somewhere in the row, in any order, so
    // "lock screen" and "spr alt" both find the same bind.
    return entries.filter(row => words.every(word => row.text.includes(word)));
  }

  function dismiss() {
    if (search.text) search.clear();
    else Settings.State.back();
  }

  function activate() {
    const row = list.currentIndex >= 0 ? rows[list.currentIndex] : null;
    if (row && row.bind.custom) Shortcuts.State.requestEditor(row.bind);
  }

  function moveFocus(delta) {
    if (list.count === 0) return;
    root.interactMode = "keyboard";
    list.currentIndex = Math.max(0, Math.min(list.count - 1, list.currentIndex + delta));
    list.positionViewAtIndex(list.currentIndex, ListView.Contain);
  }

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
    // A new result set starts without a keyboard selection.
    onModelChanged: currentIndex = -1
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
      Accessible.onPressAction: if (row.editAccess) Shortcuts.State.requestEditor(row.modelData.bind)

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
        id: hover; cursorShape: row.editAccess ? Qt.PointingHandCursor : Qt.ArrowCursor
        onHoveredChanged: if (hovered) {
          root.interactMode = "cursor";
          list.currentIndex = row.index;
        }
      }
      TapHandler {
        onTapped: {
          root.interactMode = "cursor";
          list.currentIndex = row.index;
          if (row.editAccess) Shortcuts.State.requestEditor(row.modelData.bind);
        }
      }
    }
  }

  Column {
    // Empty state: only when a search matches nothing (the full list is
    // never empty once binds load).
    objectName: "shortcutsEmpty"
    x: 30; width: root.width - 60
    y: list.y + (list.height - height) / 2
    visible: list.count === 0 && root.query !== ""
    spacing: 6

    Text {
      width: parent.width
      text: "No shortcut matches \u201c" + root.query + "\u201d"
      color: "white"; opacity: 0.5
      horizontalAlignment: Text.AlignHCenter
      font.family: Shell.Theme.fontFamily; font.pixelSize: 15
    }
    Text {
      width: parent.width
      text: "Create it below, or clear the search"
      color: "white"; opacity: 0.3
      horizontalAlignment: Text.AlignHCenter
      font.family: Shell.Theme.fontFamily; font.pixelSize: 13
    }
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
        Keys.onEscapePressed: root.dismiss()
        Keys.onReturnPressed: root.activate()
        Keys.onEnterPressed: root.activate()
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
      // Between the title and the search bar; clicking dismisses it.
      visible: Shortcuts.State.error !== ""
      x: 30; y: 62; width: root.width - 60; height: 18
      color: "transparent"
      Text {
        width: parent.width; anchors.verticalCenter: parent.verticalCenter
        text: Shortcuts.State.error; color: "#ffb4ab"; elide: Text.ElideRight
        font.family: Shell.Theme.fontFamily; font.pixelSize: 12
      }
      MouseArea { anchors.fill: parent; onClicked: Shortcuts.State.error = "" }
    },
    Rectangle {
      // Renders in the header, next to the title: how many are personal.
      objectName: "shortcutsCount"
      x: root.width - 130; y: 30
      visible: root.width > 500 && root.customCount > 0
      width: 100; height: 22; radius: 11
      color: "transparent"
      border.width: 1; border.color: "#4a4a4a"
      Text {
        anchors.centerIn: parent
        text: root.customCount + " personal"
        color: "white"; opacity: 0.5
        font.family: Shell.Theme.fontFamily; font.pixelSize: 10
      }
    }
  ]
}
