pragma ComponentBehavior: Bound

import QtQuick
import ".." as Settings
import "." as Shortcuts
import "../.." as Shell

Settings.Modal {
  id: root
  objectName: "shortcutsEditor"
  title: root.editing ? "Edit shortcut" : "New shortcut"
  bodyTop: 92
  contentHeight: form.height + 76
  onBackRequested: Settings.State.back()
  Keys.onEscapePressed: Settings.State.back()

  // Chord capture happens inside the combination box: press-and-hold shows
  // modifier keycaps live, a non-modifier key finalizes, Escape cancels.
  readonly property var editing: Shortcuts.State.editing
  readonly property var catalogItem: editing ? root.catalogEntry(editing.action) : null
  property string name: editing ? (editing.title || "") : ""
  // Binds whose action isn't in the catalog reopen as a custom command.
  property string selectedAction: catalogItem ? catalogItem.action : ""
  readonly property bool customMode: selectedAction === ""
  property bool shellCommand: !!editing && !catalogItem && /^spawn-sh /.test(editing.action)
  property string customCommand: editing && !catalogItem ? root.commandText(editing.action) : ""
  property bool repeatAllowed: !!editing && !!editing.flags && editing.flags.repeat !== false
  property bool saving: false
  property bool recording: false
  property var stagedMods: []
  property var chordParts: editing ? String(editing.key).split("+") : []
  property string hint: ""

  readonly property var order: ["Mod", "Shift", "Ctrl", "Alt", "Super"]
  readonly property string chord: root.chordParts.join("+")
  readonly property string actionValue: {
    if (root.customMode) {
      const command = root.customCommand.trim();
      if (command === "") return "";
      return root.shellCommand
          ? "spawn-sh \"" + command.replace(/[\\"]/g, "\\$&") + "\""
          : "spawn " + root.splitCommand(command);
    }
    return root.selectedAction;
  }
  readonly property bool conflict: {
    if (root.chord === "") return false;
    const wanted = root.canonical(root.chord);
    const original = root.editing ? root.canonical(root.editing.key) : "";
    return wanted !== original
        && Shortcuts.State.binds.some(bind => root.canonical(bind.key) === wanted);
  }
  readonly property bool valid: root.chord !== "" && root.actionValue !== "" && !root.conflict

  // Matches shortcuts.py: niri reads modifiers and keysyms case-insensitively.
  function canonical(key) {
    const upper = root.order.map(mod => mod.toUpperCase()), mods = [];
    let chord = "";
    for (const part of String(key).split("+")) {
      const index = upper.indexOf(part.toUpperCase());
      if (index >= 0) mods.push(index);
      else if (chord !== "") return "";
      else chord = part.toLowerCase();
    }
    return mods.sort().map(index => upper[index]).join("+") + "+" + chord;
  }

  function catalogEntry(action) {
    for (const section of Shortcuts.State.catalog)
      for (const item of section.items)
        if (item.action === action) return item;
    return null;
  }

  // Inverse of actionValue for spawn and spawn-sh binds.
  function commandText(action) {
    const sh = String(action).match(/^spawn-sh "((?:[^"\\]|\\.)*)";?$/);
    if (sh) return sh[1].replace(/\\(.)/g, "$1");
    const args = String(action).match(/"((?:[^"\\]|\\.)*)"/g);
    if (!/^spawn /.test(action) || !args) return "";
    return args.map(arg => {
      const text = JSON.parse(arg);
      return /\s/.test(text) ? arg : text;
    }).join(" ");
  }

  function splitCommand(command) {
    const tokens = command.match(/"([^"]*)"|\S+/g) || [];
    return tokens.map(token =>
        token.startsWith("\"") ? token : JSON.stringify(token)).join(" ");
  }

  function save() {
    if (!root.valid || root.saving) return;
    const flags = {};
    if (root.repeatAllowed) flags.repeat = true;
    // Not editable here, but an edit must not drop it.
    if (root.editing && root.editing.flags && root.editing.flags["allow-when-locked"])
      flags["allow-when-locked"] = true;
    // Without a name a catalog action would read as "Run qs" in the list and
    // the hotkey overlay; its catalog label is the better default.
    const chosen = root.customMode ? null : root.catalogEntry(root.selectedAction);
    root.saving = true;
    Shortcuts.State.saveShortcut(
        root.editing ? root.editing.key : "",
        {
          key: root.chord,
          title: root.name.trim() || (chosen ? chosen.label : ""),
          flags: flags,
          action: root.actionValue
        },
        () => Settings.State.back(), () => { root.saving = false; });
  }

  function remove() {
    if (!root.editing || root.saving) return;
    root.saving = true;
    Shortcuts.State.removeShortcut(root.editing.key,
        () => Settings.State.back(), () => { root.saving = false; });
  }

  // Modifier snapshot of an event; Super is Qt's MetaModifier.
  function allMods(modifiers) {
    const mods = [];
    if (modifiers & Qt.MetaModifier) mods.push("Mod");
    if (modifiers & Qt.ShiftModifier) mods.push("Shift");
    if (modifiers & Qt.ControlModifier) mods.push("Ctrl");
    if (modifiers & Qt.AltModifier) mods.push("Alt");
    return mods;
  }

  // Modifier keys themselves, mapped to the chord name they stand for.
  readonly property var modifierKeys: ({
    [Qt.Key_Meta]: "Mod", [Qt.Key_Super_L]: "Mod", [Qt.Key_Super_R]: "Mod",
    [Qt.Key_Shift]: "Shift", [Qt.Key_Control]: "Ctrl",
    [Qt.Key_Alt]: "Alt", [Qt.Key_AltGr]: "Alt"
  })
  // niri binds name the unshifted key (Mod+Shift+Slash), while Qt reports
  // the shifted symbol; this folds a US layout back.
  readonly property var keyNames: ({
    [Qt.Key_Space]: "Space", [Qt.Key_Tab]: "Tab", [Qt.Key_Backtab]: "Tab",
    [Qt.Key_Return]: "Return", [Qt.Key_Enter]: "Return",
    [Qt.Key_Backspace]: "Backspace", [Qt.Key_Delete]: "Delete",
    [Qt.Key_Insert]: "Insert", [Qt.Key_Home]: "Home", [Qt.Key_End]: "End",
    [Qt.Key_PageUp]: "Page_Up", [Qt.Key_PageDown]: "Page_Down",
    [Qt.Key_Left]: "Left", [Qt.Key_Right]: "Right", [Qt.Key_Up]: "Up", [Qt.Key_Down]: "Down",
    [Qt.Key_Minus]: "Minus", [Qt.Key_Underscore]: "Minus",
    [Qt.Key_Equal]: "Equal", [Qt.Key_Plus]: "Equal",
    [Qt.Key_Slash]: "Slash", [Qt.Key_Question]: "Slash",
    [Qt.Key_Comma]: "Comma", [Qt.Key_Less]: "Comma",
    [Qt.Key_Period]: "Period", [Qt.Key_Greater]: "Period",
    [Qt.Key_Semicolon]: "Semicolon", [Qt.Key_Colon]: "Semicolon",
    [Qt.Key_Apostrophe]: "Apostrophe", [Qt.Key_QuoteDbl]: "Apostrophe",
    [Qt.Key_BracketLeft]: "BracketLeft", [Qt.Key_BraceLeft]: "BracketLeft",
    [Qt.Key_BracketRight]: "BracketRight", [Qt.Key_BraceRight]: "BracketRight",
    [Qt.Key_Backslash]: "Backslash", [Qt.Key_Bar]: "Backslash",
    [Qt.Key_QuoteLeft]: "Grave", [Qt.Key_AsciiTilde]: "Grave",
    [Qt.Key_Exclam]: "1", [Qt.Key_At]: "2", [Qt.Key_NumberSign]: "3", [Qt.Key_Dollar]: "4",
    [Qt.Key_Percent]: "5", [Qt.Key_AsciiCircum]: "6", [Qt.Key_Ampersand]: "7",
    [Qt.Key_Asterisk]: "8", [Qt.Key_ParenLeft]: "9", [Qt.Key_ParenRight]: "0",
    [Qt.Key_Print]: "Print",
    [Qt.Key_MediaPlay]: "XF86AudioPlay", [Qt.Key_MediaPause]: "XF86AudioPause",
    [Qt.Key_MediaStop]: "XF86AudioStop", [Qt.Key_MediaNext]: "XF86AudioNext",
    [Qt.Key_MediaPrevious]: "XF86AudioPrev",
    [Qt.Key_VolumeUp]: "XF86AudioRaiseVolume", [Qt.Key_VolumeDown]: "XF86AudioLowerVolume",
    [Qt.Key_VolumeMute]: "XF86AudioMute", [Qt.Key_MicMute]: "XF86AudioMicMute"
  })

  // Held modifiers, in chord order. Whether an event's own modifier key is
  // already in event.modifiers varies by platform, so it is passed apart.
  function heldMods(modifiers, pressed, released) {
    const held = root.allMods(modifiers);
    if (pressed && held.indexOf(pressed) < 0) held.push(pressed);
    return root.order.filter(mod => mod !== released && held.indexOf(mod) >= 0);
  }

  function stopRecording() {
    root.recording = false;
    root.stagedMods = [];
  }

  function capture(event) {
    const modifier = root.modifierKeys[event.key];
    if (modifier !== undefined) {
      root.stagedMods = root.heldMods(event.modifiers, modifier, "");
      return;
    }
    const key = root.keySym(event);
    if (key === "") return;
    root.chordParts = root.heldMods(event.modifiers, "", "").concat([key]);
    root.stopRecording();
    root.hint = "";
  }

  function keySym(event) {
    const key = event.key;
    if (key >= Qt.Key_A && key <= Qt.Key_Z) return String.fromCharCode(key);
    if (key >= Qt.Key_0 && key <= Qt.Key_9) return String.fromCharCode(key);
    if (key >= Qt.Key_F1 && key <= Qt.Key_F35) return "F" + (key - Qt.Key_F1 + 1);
    const name = root.keyNames[key];
    if (name !== undefined) return name;
    if (event.text && event.text.length === 1 && /[a-z0-9]/i.test(event.text))
      return event.text.toUpperCase();
    root.hint = "That key isn't supported here. Try another one.";
    return "";
  }

  Column {
    id: form
    x: 30; width: root.width - 60; spacing: 10

    Text {
      text: "Name"; color: "#b3b3b3"
      font.family: Shell.Theme.fontFamily; font.pixelSize: 13
    }
    Rectangle {
      objectName: "shortcutsNameInput"
      width: parent.width; height: 51; radius: 12
      color: nameInput.activeFocus ? "#303030" : "#262626"
      Text {
        x: 20; anchors.verticalCenter: parent.verticalCenter
        visible: !nameInput.text
        text: "How the shortcut reads in lists (optional)"
        color: "white"; opacity: 0.2
        font.family: Shell.Theme.fontFamily; font.pixelSize: 15
      }
      TextInput {
        id: nameInput
        x: 20; width: parent.width - 40; anchors.verticalCenter: parent.verticalCenter
        text: root.name
        onTextChanged: root.name = text
        clip: true; color: "white"
        selectionColor: Shell.PanelStyle.accentText; selectedTextColor: "white"
        font.family: Shell.Theme.fontFamily; font.pixelSize: 15
        cursorDelegate: Rectangle {
          id: nameCaret
          width: 1; color: Shell.PanelStyle.accent
          Timer {
            running: nameInput.cursorVisible; repeat: true
            interval: Qt.styleHints.cursorFlashTime / 2
            onRunningChanged: nameCaret.opacity = 1
            onTriggered: nameCaret.opacity = 1 - nameCaret.opacity
          }
        }
      }
    }

    Text {
      text: "Combination"; color: "#b3b3b3"
      font.family: Shell.Theme.fontFamily; font.pixelSize: 13
    }
    Rectangle {
      id: chordBox
      objectName: "shortcutsChord"
      width: parent.width; height: 51; radius: 12
      color: root.recording ? "#303030" : "#262626"
      border.width: root.recording ? 1 : 0
      border.color: Shell.PanelStyle.accent
      activeFocusOnTab: true
      Accessible.role: Accessible.Button
      Accessible.name: root.chord === "" ? "Record a key combination"
          : root.chord.split("+").join(" plus ")

      // While recording every key is captured; Escape cancels the recording
      // instead of leaving the page.
      Keys.onPressed: event => {
        if (!root.recording) {
          event.accepted = false;
        } else if (event.key === Qt.Key_Escape) {
          root.stopRecording();
          event.accepted = true;
        } else {
          root.capture(event);
          event.accepted = true;
        }
      }
      Keys.onReleased: event => {
        const modifier = root.modifierKeys[event.key];
        if (root.recording && modifier !== undefined)
          root.stagedMods = root.heldMods(event.modifiers, "", modifier);
        event.accepted = root.recording;
      }
      onActiveFocusChanged: if (!activeFocus) root.stopRecording()

      Text {
        x: 20; anchors.verticalCenter: parent.verticalCenter
        visible: root.chord === "" && !root.recording
        text: "Click, then press keys to record a combination"
        color: "white"; opacity: 0.2
        font.family: Shell.Theme.fontFamily; font.pixelSize: 15
      }
      Text {
        x: 20; anchors.verticalCenter: parent.verticalCenter
        visible: root.recording && root.stagedMods.length === 0
        text: "Hold modifiers, then press another key"
        color: Shell.PanelStyle.accent; opacity: 0.8
        font.family: Shell.Theme.fontFamily; font.italic: true
        font.pixelSize: 15
      }
      Shortcuts.Keys {
        id: chordPreview
        chord: root.recording ? root.stagedMods.join("+") : root.chord
        visible: chord.length > 0
        size: 24
        anchors.left: parent.left; anchors.leftMargin: 20
        anchors.verticalCenter: parent.verticalCenter
      }
      Text {
        anchors.right: parent.right; anchors.rightMargin: 20
        anchors.verticalCenter: parent.verticalCenter
        visible: root.recording
        text: "esc \u2022 cancel"; color: "white"; opacity: 0.3
        font.family: Shell.Theme.fontFamily; font.pixelSize: 11
      }
      HoverHandler { cursorShape: Qt.PointingHandCursor }
      TapHandler {
        onTapped: {
          root.recording = true;
          root.hint = "";
          chordBox.forceActiveFocus();
        }
      }
    }
    Text {
      width: parent.width
      visible: text !== ""
      text: root.conflict ? "That combination is already in use."
          : root.hint || Shortcuts.State.error
      color: "#ffb4ab"; wrapMode: Text.Wrap
      font.family: Shell.Theme.fontFamily; font.pixelSize: 12
    }

    Rectangle {
      objectName: "shortcutsRepeatToggle"
      width: 190; height: 36; radius: 18
      color: "transparent"; border.width: 1; border.color: "#303030"
      Text {
        x: 16; anchors.verticalCenter: parent.verticalCenter
        text: "Repeat while held"; color: "white"; opacity: 0.5
        font.family: Shell.Theme.fontFamily; font.pixelSize: 12
      }
      Shell.Toggle {
        anchors.right: parent.right; anchors.rightMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        checked: root.repeatAllowed
        onToggled: checked => { root.repeatAllowed = checked; }
      }
    }

    Text {
      text: "Action"; color: "#b3b3b3"
      font.family: Shell.Theme.fontFamily; font.pixelSize: 13
    }
    Repeater {
      model: Shortcuts.State.catalog

      Column {
        id: section
        width: parent.width; spacing: 8
        required property var modelData

        Text {
          text: section.modelData.name
          color: "white"; opacity: 0.3
          font.family: Shell.Theme.fontFamily
          font.pixelSize: 11; font.letterSpacing: 0.5
        }
        Repeater {
          model: section.modelData.items

          Rectangle {
            id: action
            required property var modelData
            readonly property bool chosen: !root.customMode && root.selectedAction === modelData.action
            width: section.width; height: 44; radius: 12
            color: hover.hovered || chosen ? "#262626" : "transparent"
            Text {
              x: 20; anchors.verticalCenter: parent.verticalCenter
              text: action.modelData.label; color: "white"; opacity: action.chosen ? 1 : 0.7
              font.family: Shell.Theme.fontFamily; font.pixelSize: 15
            }
            Text {
              // Steps aside for the check mark, which sits where the custom
              // command row puts its own.
              anchors.right: parent.right; anchors.rightMargin: action.chosen ? 52 : 20
              anchors.verticalCenter: parent.verticalCenter
              width: Math.min(180, implicitWidth); elide: Text.ElideMiddle
              text: action.modelData.action.replace(/;$/, "")
              color: "white"; opacity: 0.25
              font.family: "JetBrains Mono"; font.pixelSize: 12
            }
            Image {
              visible: action.chosen
              x: parent.width - 42; anchors.verticalCenter: parent.verticalCenter
              width: 20; height: 20; sourceSize: Qt.size(40, 40)
              source: Qt.resolvedUrl("../../assets/installs/check.svg")
            }
            HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
            TapHandler {
              onTapped: {
                root.selectedAction = action.modelData.action;
                root.customCommand = "";
              }
            }
          }
        }
      }
    }

    Rectangle {
      id: customRow
      width: parent.width; height: 44; radius: 12
      color: customHover.hovered || root.customMode ? "#262626" : "transparent"
      Text {
        x: 20; anchors.verticalCenter: parent.verticalCenter
        text: "Custom command" + (root.customMode ? "" : "\u2026")
        color: "white"; opacity: root.customMode ? 1 : 0.7
        font.family: Shell.Theme.fontFamily; font.pixelSize: 15
      }
      Image {
        visible: root.customMode
        x: customRow.width - 42; anchors.verticalCenter: parent.verticalCenter
        width: 20; height: 20; sourceSize: Qt.size(40, 40)
        source: Qt.resolvedUrl("../../assets/installs/check.svg")
      }
      Text {
        visible: !root.customMode
        anchors.right: parent.right; anchors.rightMargin: 20
        anchors.verticalCenter: parent.verticalCenter
        text: "any app or script"; color: "white"; opacity: 0.25
        font.family: "JetBrains Mono"; font.pixelSize: 12
      }
      HoverHandler { id: customHover; cursorShape: Qt.PointingHandCursor }
      TapHandler { onTapped: root.selectedAction = ""; }
    }
    Column {
      visible: root.customMode
      width: parent.width; spacing: 8
      Row {
        spacing: 8
        Rectangle {
          width: 96; height: 32; radius: 16
          color: !root.shellCommand ? "#303030" : "transparent"
          border.width: 1; border.color: "#303030"
          Text {
            anchors.centerIn: parent; text: "App"; color: "white"
            opacity: !root.shellCommand ? 0.9 : 0.5
            font.family: Shell.Theme.fontFamily; font.pixelSize: 12
          }
          HoverHandler { cursorShape: Qt.PointingHandCursor }
          TapHandler { onTapped: root.shellCommand = false }
        }
        Rectangle {
          width: 120; height: 32; radius: 16
          color: root.shellCommand ? "#303030" : "transparent"
          border.width: 1; border.color: "#303030"
          Text {
            anchors.centerIn: parent; text: "Shell script"; color: "white"
            opacity: root.shellCommand ? 0.9 : 0.5
            font.family: Shell.Theme.fontFamily; font.pixelSize: 12
          }
          HoverHandler { cursorShape: Qt.PointingHandCursor }
          TapHandler { onTapped: root.shellCommand = true }
        }
      }
      Rectangle {
        objectName: "shortcutsCommandInput"
        width: parent.width; height: 51; radius: 12
        color: commandInput.activeFocus ? "#303030" : "#262626"
        Text {
          x: 20; anchors.verticalCenter: parent.verticalCenter
          visible: !commandInput.text
          text: root.shellCommand ? "script to run, e.g. ~/scripts/screenshot.sh"
              : "command with flags, e.g. brave https://bflycomputer.so"
          color: "white"; opacity: 0.2
          font.family: "JetBrains Mono"; font.pixelSize: 14
        }
        TextInput {
          id: commandInput
          x: 20; width: parent.width - 40; anchors.verticalCenter: parent.verticalCenter
          text: root.customCommand
          onTextChanged: root.customCommand = text
          clip: true; color: "white"
          font.family: "JetBrains Mono"; font.pixelSize: 14
          selectionColor: Shell.PanelStyle.accentText; selectedTextColor: "white"
        }
      }
    }
  }

  // Bottom-right controls sit on the overlay so scrolled content can't
  // push them off the card.
  overlay: Row {
    x: root.width - width - 24; y: root.height - 58; spacing: 8

    Rectangle {
      objectName: "shortcutsEditorDelete"
      visible: !!root.editing
      width: 84; height: 40; radius: 8
      color: deleteHover.hovered ? "#3a2622" : "transparent"
      border.width: 1; border.color: "#4a4a4a"
      Text {
        anchors.centerIn: parent; text: "Delete"
        color: "#ffb4ab"
        font.family: Shell.Theme.fontFamily; font.pixelSize: 13
      }
      HoverHandler { id: deleteHover; cursorShape: Qt.PointingHandCursor }
      TapHandler { onTapped: root.remove() }
    }
    Rectangle {
      objectName: "shortcutsEditorCancel"
      width: 84; height: 40; radius: 8
      color: cancelHover.hovered ? "#303030" : "transparent"
      border.width: 1; border.color: "#4a4a4a"
      Text {
        anchors.centerIn: parent; text: "Cancel"
        color: "white"; opacity: 0.7
        font.family: Shell.Theme.fontFamily; font.pixelSize: 13
      }
      HoverHandler { id: cancelHover; cursorShape: Qt.PointingHandCursor }
      TapHandler { onTapped: Settings.State.back() }
    }
    Rectangle {
      objectName: "shortcutsEditorSave"
      width: 110; height: 40; radius: 8
      color: root.valid ? "#cba6f7" : "#3a2f45"
      opacity: root.valid && !root.saving ? 1 : 0.45
      Text {
        anchors.centerIn: parent
        text: root.editing ? "Save changes" : "Add shortcut"
        color: root.valid ? "#1d1d1d" : "white"
        opacity: root.valid ? 1 : 0.5
        font.family: Shell.Theme.fontFamily
        font.weight: Font.DemiBold; font.pixelSize: 13
      }
      HoverHandler { id: saveHover; cursorShape: root.valid ? Qt.PointingHandCursor : Qt.ArrowCursor }
      TapHandler { enabled: root.valid; onTapped: root.save() }
    }
  }
}
