pragma ComponentBehavior: Bound

import QtQuick
import ".." as Settings
import "." as Shortcuts
import "../.." as Shell

// Every niri binding. Clicking a built-in row records new keys for it in
// place; personal rows open the editor.
Settings.Modal {
  id: root
  objectName: "shortcutsPanel"
  title: "Keyboard shortcuts"
  bodyTop: 143
  roundedContent: true
  // Sized from the unfiltered list and capped at the window, so searching
  // never resizes the card and only the list scrolls, never the body.
  contentHeight: Math.min(heightOf(grouped) + list.bottomMargin + barSize, availableHeight - bodyTop)
  onBackRequested: Settings.State.back()
  Keys.onEscapePressed: root.dismiss()
  Keys.onDownPressed: root.moveFocus(1)
  Keys.onUpPressed: root.moveFocus(-1)
  Keys.onReturnPressed: root.activate(list.currentIndex)
  Keys.onEnterPressed: root.activate(list.currentIndex)
  // Typing to search is the first thing people do here.
  Component.onCompleted: Qt.callLater(() => search.forceActiveFocus())

  readonly property string query: search.text.trim().toLowerCase()
  // Exactly one highlight is visible at a time: the keyboard's when arrows
  // are used, the cursor's otherwise. Hover keeps the two in sync so the
  // states hand over instead of stacking.
  property string interactMode: "cursor"
  readonly property real bottomGap: 24
  readonly property real barSize: 50 + bottomGap
  readonly property real rowHeight: 50
  readonly property real headerHeight: 28

  // The row whose keys are being recorded, by its current chord.
  property string recordingKey: ""
  property string staged: ""
  property string recordHint: ""
  // After a rebind the row may move (a Pond default becomes a personal
  // line); follow it so it never just vanishes.
  property string followKey: ""

  // Search treats these words as modifier chips: "spr c" is Mod+C.
  readonly property var modWords: ({
    spr: "Mod", super: "Mod", mod: "Mod", win: "Mod", meta: "Mod",
    shift: "Shift", ctrl: "Ctrl", ctl: "Ctrl", control: "Ctrl", alt: "Alt"
  })

  // Built once per reload; typing only filters.
  readonly property var entries: Shortcuts.State.binds.map(bind => {
    const label = Shortcuts.State.label(bind);
    const parts = String(bind.key).split("+");
    const key = parts[parts.length - 1];
    return {
      bind: bind, label: label,
      mods: parts.slice(0, -1).map(part => Shortcuts.State.order.find(mod =>
          mod.toUpperCase() === part.toUpperCase()) || part).sort(),
      keys: [Shortcuts.State.chipText(key), key.toLowerCase()],
      text: (label + " " + bind.key + " " + bind.action + " "
          + Shortcuts.State.chipsText(bind)).toLowerCase()
    };
  })
  readonly property var personal: entries.filter(row => row.bind.custom)
  readonly property var stock: entries.filter(row => !row.bind.custom)
  // Headers only earn their space once there is something to separate.
  readonly property var grouped: personal.length === 0 ? stock
      : [{ header: "Added by you" }].concat(personal, [{ header: "Built in" }], stock)
  readonly property var rows: {
    const words = query.split(/\s+/).filter(word => word !== "");
    if (words.length === 0) return grouped;
    const pool = personal.concat(stock);
    return chordMatches(words, pool) || pool.filter(row => words.every(word => row.text.includes(word)));
  }

  // "spr c" means exactly Mod+C, not every row mentioning a "c"; "spr"
  // alone lists everything on Super. Falls back to text search otherwise.
  function chordMatches(words, pool) {
    const mods = words.filter(word => modWords[word] !== undefined).map(word => modWords[word]);
    const rest = words.filter(word => modWords[word] === undefined);
    if (mods.length === 0 || rest.length > 1) return null;
    const wanted = Array.from(new Set(mods)).sort().join("+");
    if (rest.length === 0)
      return pool.filter(row => mods.every(mod => row.mods.indexOf(mod) >= 0));
    const same = pool.filter(row => row.mods.join("+") === wanted);
    const exact = same.filter(row => row.keys.indexOf(rest[0]) >= 0);
    if (exact.length > 0) return exact;
    const started = same.filter(row => row.keys.some(key => key.startsWith(rest[0])));
    return started.length > 0 ? started : null;
  }

  function heightOf(model) {
    return model.reduce((sum, row) => sum + (row.header ? headerHeight : rowHeight) + list.spacing, 0)
        - (model.length > 0 ? list.spacing : 0);
  }

  function dismiss() {
    if (root.recordingKey !== "") root.stopRecording();
    else Settings.State.close();
  }

  function activate(index) {
    const row = index >= 0 ? rows[index] : null;
    if (!row || row.header) return;
    if (row.bind.custom) Shortcuts.State.requestEditor(row.bind);
    else root.startRecording(row.bind.key);
  }

  function startRecording(key) {
    Shortcuts.State.error = "";
    root.recordingKey = key;
    root.staged = "";
    root.recordHint = "";
    recorder.forceActiveFocus();
  }

  function stopRecording() {
    root.recordingKey = "";
    root.staged = "";
    root.recordHint = "";
    search.forceActiveFocus();
  }

  function record(chord) {
    if (Shortcuts.State.canonical(chord) === Shortcuts.State.canonical(root.recordingKey)) {
      root.stopRecording();
      return;
    }
    const conflict = Shortcuts.State.conflictWith(chord, root.recordingKey);
    if (conflict) {
      // Stay in recording so another combination can be tried right away.
      root.staged = "";
      root.recordHint = Shortcuts.State.chipsText({ key: chord }) + " is used by "
          + Shortcuts.State.label(conflict);
      return;
    }
    const oldKey = root.recordingKey;
    root.stopRecording();
    root.followKey = chord;
    Shortcuts.State.rebind(oldKey, chord, null, () => { root.followKey = ""; });
  }

  function moveFocus(delta) {
    if (list.count === 0 || root.recordingKey !== "") return;
    root.interactMode = "keyboard";
    let index = list.currentIndex;
    do index += delta;
    while (index >= 0 && index < rows.length && rows[index].header);
    if (index < 0 || index >= rows.length) return;
    list.currentIndex = index;
    list.positionViewAtIndex(index, ListView.Contain);
  }

  onInteractModeChanged: if (interactMode === "cursor") list.currentIndex = -1
  onRowsChanged: {
    if (root.followKey === "") return;
    const index = rows.findIndex(row => !row.header
        && Shortcuts.State.canonical(row.bind.key) === Shortcuts.State.canonical(root.followKey));
    if (index < 0) return;
    root.followKey = "";
    Qt.callLater(() => {
      root.interactMode = "keyboard";
      list.currentIndex = index;
      list.positionViewAtIndex(index, ListView.Contain);
    });
  }

  Item {
    // Takes the keyboard while a row records, so typing never lands in search.
    id: recorder
    Keys.onPressed: event => {
      event.accepted = true;
      if (event.key === Qt.Key_Escape) { root.stopRecording(); return; }
      const chord = Shortcuts.State.readChord(event, mods => { root.staged = mods.join("+"); });
      if (chord === null) return;
      if (chord === "") { root.recordHint = "That key can't be used in a shortcut"; return; }
      root.record(chord);
    }
    Keys.onReleased: event => {
      const modifier = Shortcuts.State.modifierKeys[event.key];
      if (modifier !== undefined)
        root.staged = Shortcuts.State.heldMods(event.modifiers, "", modifier).join("+");
      event.accepted = true;
    }
    onActiveFocusChanged: if (!activeFocus && root.recordingKey !== "") {
      root.recordingKey = "";
      root.staged = "";
      root.recordHint = "";
    }
  }

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

    delegate: Item {
      id: row
      required property var modelData
      required property int index
      readonly property bool header: !!modelData.header
      readonly property bool custom: !header && modelData.bind.custom
      readonly property bool recording: !header && root.recordingKey === modelData.bind.key
      readonly property bool highlighted: !header && (root.interactMode === "keyboard"
          ? list.currentIndex === index : hover.hovered)

      width: list.width
      height: header ? root.headerHeight : root.rowHeight

      Text {
        visible: row.header
        x: 20; anchors.bottom: parent.bottom; anchors.bottomMargin: 4
        text: row.header ? row.modelData.header : ""
        color: "white"; opacity: 0.35
        font.family: Shell.Theme.fontFamily; font.pixelSize: 12; font.letterSpacing: 0.3
      }

      Rectangle {
        visible: !row.header
        anchors.fill: parent; radius: 12
        color: row.recording ? "#303030" : row.highlighted ? "#262626" : "transparent"
        border.width: row.recording ? 1 : 0
        border.color: root.recordHint !== "" ? "#ffb4ab" : Shell.PanelStyle.accent
        Accessible.role: Accessible.Button
        Accessible.name: row.header ? "" : row.modelData.label + ", " + row.modelData.bind.key
            + (row.custom ? ", edit" : ", change keys")
        Accessible.onPressAction: root.activate(row.index)

        Text {
          id: name
          x: 20; width: Math.min(implicitWidth, parent.width - keysArea.width - 56)
          anchors.verticalCenter: parent.verticalCenter
          text: row.header ? "" : row.modelData.label; elide: Text.ElideRight
          color: "white"; opacity: row.custom || row.highlighted || row.recording ? 1 : 0.7
          font.family: Shell.Theme.fontFamily; font.pixelSize: 15
        }
        Row {
          id: keysArea
          anchors.right: parent.right
          anchors.rightMargin: row.custom ? 36 : 12
          anchors.verticalCenter: parent.verticalCenter
          spacing: 10

          Text {
            // Says what a click does, only where the cursor or keyboard is.
            anchors.verticalCenter: parent.verticalCenter
            visible: row.recording ? root.staged === "" : row.highlighted && !row.custom
            text: !row.recording ? "Change keys"
                : root.recordHint !== "" ? root.recordHint : "Press new keys • esc to cancel"
            color: row.recording && root.recordHint !== "" ? "#ffb4ab"
                : row.recording ? Shell.PanelStyle.accent : "white"
            opacity: row.recording ? 0.9 : 0.35
            font.family: Shell.Theme.fontFamily; font.pixelSize: 12
            font.italic: row.recording && root.recordHint === ""
          }
          Shortcuts.Keys {
            anchors.verticalCenter: parent.verticalCenter
            visible: !row.recording || root.staged !== ""
            chord: row.header ? "" : row.recording ? root.staged : row.modelData.bind.key
            complete: !row.recording
            borderColor: row.recording ? Shell.PanelStyle.accent : "#4a4a4a"
          }
        }
        Image {
          visible: row.custom
          anchors.right: parent.right; anchors.rightMargin: 12
          anchors.verticalCenter: parent.verticalCenter
          width: 16; height: 16; sourceSize: Qt.size(32, 32)
          source: Qt.resolvedUrl("../../assets/appearance/chevron.svg")
          rotation: -90
        }

        HoverHandler {
          id: hover; cursorShape: Qt.PointingHandCursor
          onHoveredChanged: if (hovered && root.recordingKey === "") {
            root.interactMode = "cursor";
            list.currentIndex = row.index;
          }
        }
        TapHandler {
          onTapped: {
            if (row.recording) return;
            if (root.recordingKey !== "") root.stopRecording();
            root.interactMode = "cursor";
            list.currentIndex = row.index;
            root.activate(row.index);
          }
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
      text: "No shortcut matches “" + root.query + "”"
      color: "white"; opacity: 0.5
      horizontalAlignment: Text.AlignHCenter
      font.family: Shell.Theme.fontFamily; font.pixelSize: 15
    }
    Text {
      width: parent.width
      text: "Add one below, or try other words"
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
        visible: !search.text; text: "Search by name or keys, like “spr c”"
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
        Keys.onReturnPressed: root.activate(list.currentIndex)
        Keys.onEnterPressed: root.activate(list.currentIndex)
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
      Text {
        anchors.right: parent.right; anchors.rightMargin: 20
        anchors.verticalCenter: parent.verticalCenter
        text: "open an app or run a script"; color: "white"; opacity: 0.3
        font.family: Shell.Theme.fontFamily; font.pixelSize: 12
      }
      HoverHandler { id: addHover; cursorShape: Qt.PointingHandCursor }
      TapHandler { onTapped: Shortcuts.State.newShortcut() }
    },
    Rectangle {
      // Between the title and the search bar; clicking dismisses it.
      objectName: "shortcutsOverlayError"
      visible: Shortcuts.State.error !== ""
      x: 30; y: 62; width: root.width - 60; height: 18
      color: "transparent"
      Text {
        width: parent.width; anchors.verticalCenter: parent.verticalCenter
        text: Shortcuts.State.error; color: "#ffb4ab"; elide: Text.ElideRight
        font.family: Shell.Theme.fontFamily; font.pixelSize: 12
      }
      TapHandler { onTapped: Shortcuts.State.error = "" }
    }
  ]
}
