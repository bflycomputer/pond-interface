pragma ComponentBehavior: Bound

import QtQuick
import ".." as Settings
import "." as Shortcuts
import "../.." as Shell

// Adds or edits a personal shortcut: what it runs, the keys, an optional
// name. Built-in actions are rebound from the list itself.
Settings.Modal {
  id: root
  objectName: "shortcutsEditor"
  title: root.editing ? "Edit shortcut" : "New shortcut"
  bodyTop: 92
  contentHeight: form.height + 24 + footerHeight
  onBackRequested: Settings.State.back()
  Keys.onEscapePressed: Settings.State.back()
  // The command is what people come here to type.
  Component.onCompleted: Qt.callLater(() => commandInput.forceActiveFocus())

  readonly property real footerHeight: 76
  readonly property var editing: Shortcuts.State.editing
  // Binds made before the editor only took commands keep their niri action
  // until a command replaces it.
  readonly property string keptAction: editing && commandText(editing.action) === "" ? editing.action : ""
  property string name: editing ? (editing.title || "") : ""
  property bool shellCommand: !!editing && /^spawn-sh /.test(editing.action)
  property string customCommand: editing ? root.commandText(editing.action) : ""
  property bool repeatAllowed: !!editing && !!editing.flags && editing.flags.repeat !== false
  property string chord: editing ? editing.key : ""
  property bool saving: false
  property bool recording: false
  property string staged: ""
  property string hint: ""

  readonly property string actionValue: {
    const command = root.customCommand.trim();
    if (command === "") return root.keptAction;
    return root.shellCommand
        ? "spawn-sh \"" + command.replace(/[\\"]/g, "\\$&") + "\";"
        : "spawn " + root.splitCommand(command) + ";";
  }
  readonly property var conflict: root.chord === "" ? null
      : Shortcuts.State.conflictWith(root.chord, root.editing ? root.editing.key : "")
  readonly property bool valid: root.chord !== "" && root.actionValue !== "" && !root.conflict
  // What the list will call it when no name is given.
  readonly property string fallbackName: root.actionValue === "" ? ""
      : Shortcuts.State.label({ title: "", key: root.chord, action: root.actionValue })

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
    if (root.saving) return;
    // Not ready yet: lead to whatever is still missing instead of a dead button.
    if (root.actionValue === "") { commandInput.forceActiveFocus(); return; }
    if (root.chord === "") { root.startRecording(); return; }
    if (!root.valid) return;
    const flags = {};
    if (root.repeatAllowed) flags.repeat = true;
    // Not editable here, but an edit must not drop it.
    if (root.editing && root.editing.flags && root.editing.flags["allow-when-locked"])
      flags["allow-when-locked"] = true;
    root.saving = true;
    Shortcuts.State.saveShortcut(
        root.editing ? root.editing.key : "",
        { key: root.chord, title: root.name.trim(), flags: flags, action: root.actionValue },
        () => Settings.State.back(), () => { root.saving = false; });
  }

  function remove() {
    if (!root.editing || root.saving) return;
    root.saving = true;
    Shortcuts.State.removeShortcut(root.editing.key,
        () => Settings.State.back(), () => { root.saving = false; });
  }

  function startRecording() {
    root.recording = true;
    root.staged = "";
    root.hint = "";
    chordBox.forceActiveFocus();
  }

  function stopRecording() {
    root.recording = false;
    root.staged = "";
  }

  Column {
    id: form
    x: 30; width: root.width - 60; spacing: 10

    Item {
      width: parent.width; height: 28
      Text { anchors.verticalCenter: parent.verticalCenter; text: "Runs"; color: "#b3b3b3"; font.family: Shell.Theme.fontFamily; font.pixelSize: 13 }
      Row {
        anchors.right: parent.right; spacing: 6
        Shortcuts.Choice {
          label: "App"; selected: !root.shellCommand
          onPicked: { root.shellCommand = false; commandInput.forceActiveFocus(); }
        }
        Shortcuts.Choice {
          label: "Shell script"; selected: root.shellCommand
          onPicked: { root.shellCommand = true; commandInput.forceActiveFocus(); }
        }
      }
    }
    Rectangle {
      objectName: "shortcutsCommandInput"
      width: parent.width; height: 51; radius: 12
      color: commandInput.activeFocus ? "#303030" : "#262626"
      Text {
        x: 20; width: parent.width - 40; anchors.verticalCenter: parent.verticalCenter
        visible: !commandInput.text; elide: Text.ElideRight
        text: root.keptAction !== "" ? root.keptAction.replace(/;$/, "")
            : root.shellCommand ? "~/scripts/screenshot.sh --area" : "firefox --private-window"
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
        activeFocusOnTab: true
        Accessible.role: Accessible.EditableText
        Accessible.name: root.shellCommand ? "Shell script" : "App command"
        Keys.onReturnPressed: root.save()
        Keys.onEnterPressed: root.save()
      }
    }
    Text {
      width: parent.width; wrapMode: Text.Wrap
      color: "white"; opacity: 0.35
      font.family: Shell.Theme.fontFamily; font.pixelSize: 12
      text: root.shellCommand
          ? "Runs through sh -c, so pipes, ~ and $VARIABLES work."
          : "The program and its arguments. Quote an argument that contains spaces."
    }

    Item { width: 1; height: 6 }
    Text { text: "Keys"; color: "#b3b3b3"; font.family: Shell.Theme.fontFamily; font.pixelSize: 13 }
    Rectangle {
      id: chordBox
      objectName: "shortcutsChord"
      width: parent.width; height: 51; radius: 12
      color: root.recording ? "#303030" : chordHover.hovered ? "#2b2b2b" : "#262626"
      border.width: root.recording || root.conflict ? 1 : 0
      border.color: root.conflict && !root.recording ? "#ffb4ab" : Shell.PanelStyle.accent
      activeFocusOnTab: true
      Accessible.role: Accessible.Button
      Accessible.name: root.chord === "" ? "Record keys" : "Keys: " + root.chord.split("+").join(" plus ")

      // While recording every key is captured; Escape cancels the
      // recording instead of leaving the page.
      Keys.onPressed: event => {
        if (!root.recording) {
          if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
            root.startRecording();
            event.accepted = true;
          } else {
            event.accepted = false;
          }
          return;
        }
        event.accepted = true;
        if (event.key === Qt.Key_Escape) { root.stopRecording(); return; }
        const chord = Shortcuts.State.readChord(event, mods => { root.staged = mods.join("+"); });
        if (chord === null) return;
        if (chord === "") { root.hint = "That key can't be used in a shortcut. Try another one."; return; }
        root.chord = chord;
        root.hint = "";
        root.stopRecording();
      }
      Keys.onReleased: event => {
        const modifier = Shortcuts.State.modifierKeys[event.key];
        if (root.recording && modifier !== undefined)
          root.staged = Shortcuts.State.heldMods(event.modifiers, "", modifier).join("+");
        event.accepted = root.recording;
      }
      onActiveFocusChanged: if (!activeFocus) root.stopRecording()

      Text {
        x: 20; anchors.verticalCenter: parent.verticalCenter
        visible: !root.recording && root.chord === ""
        text: "Click to record keys"
        color: "white"; opacity: 0.2
        font.family: Shell.Theme.fontFamily; font.pixelSize: 15
      }
      Text {
        x: 20; anchors.verticalCenter: parent.verticalCenter
        visible: root.recording && root.staged === ""
        text: "Hold modifiers, then press a key"
        color: Shell.PanelStyle.accent; opacity: 0.8
        font.family: Shell.Theme.fontFamily; font.italic: true; font.pixelSize: 15
      }
      Shortcuts.Keys {
        x: 20; anchors.verticalCenter: parent.verticalCenter
        chord: root.recording ? root.staged : root.chord
        complete: !root.recording
        borderColor: root.recording ? Shell.PanelStyle.accent : "#4a4a4a"
      }
      Text {
        anchors.right: parent.right; anchors.rightMargin: 20
        anchors.verticalCenter: parent.verticalCenter
        text: root.recording ? "esc • cancel" : root.chord === "" ? "" : "click to change"
        color: "white"; opacity: root.recording || chordHover.hovered ? 0.35 : 0
        font.family: Shell.Theme.fontFamily; font.pixelSize: 11
      }
      HoverHandler { id: chordHover; cursorShape: Qt.PointingHandCursor }
      TapHandler { onTapped: root.startRecording() }
    }
    Text {
      width: parent.width; wrapMode: Text.Wrap
      visible: text !== ""
      color: "#ffb4ab"
      font.family: Shell.Theme.fontFamily; font.pixelSize: 12
      text: root.conflict
          ? "Already used by “" + Shortcuts.State.label(root.conflict) + "”. Pick other keys."
          : root.hint
    }

    Item { width: 1; height: 6 }
    Text { text: "Name"; color: "#b3b3b3"; font.family: Shell.Theme.fontFamily; font.pixelSize: 13 }
    Rectangle {
      objectName: "shortcutsNameInput"
      width: parent.width; height: 51; radius: 12
      color: nameInput.activeFocus ? "#303030" : "#262626"
      Text {
        x: 20; width: parent.width - 40; anchors.verticalCenter: parent.verticalCenter
        visible: !nameInput.text; elide: Text.ElideRight
        text: root.fallbackName !== "" ? root.fallbackName + "  (optional)" : "Optional"
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
        activeFocusOnTab: true
        Accessible.role: Accessible.EditableText
        Accessible.name: "Name"
        Keys.onReturnPressed: root.save()
        Keys.onEnterPressed: root.save()
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
      width: parent.width; wrapMode: Text.Wrap
      color: "white"; opacity: 0.35
      font.family: Shell.Theme.fontFamily; font.pixelSize: 12
      text: "Shown in this list and in the hotkey overlay."
    }

    Item { width: 1; height: 6 }
    Settings.Field {
      objectName: "shortcutsRepeatToggle"
      width: parent.width
      title: "Repeat while held"
      toggle: true; checked: root.repeatAllowed
      onToggled: checked => { root.repeatAllowed = checked; }
    }
  }

  overlay: Item {
    // A solid footer: scrolled content passes under it, never through it.
    objectName: "shortcutsEditorFooter"
    y: root.height - root.footerHeight
    width: root.width; height: root.footerHeight

    Rectangle {
      anchors.fill: parent
      radius: root.radius; color: Settings.Style.card
      Rectangle { width: parent.width; height: root.radius; color: Settings.Style.card }
      Rectangle { x: 30; width: parent.width - 60; height: 1; color: "#2a2a2a" }
    }
    Text {
      x: 30; width: parent.width - 330; anchors.verticalCenter: parent.verticalCenter
      visible: Shortcuts.State.error !== ""
      text: Shortcuts.State.error; color: "#ffb4ab"
      elide: Text.ElideRight; maximumLineCount: 2; wrapMode: Text.Wrap
      font.family: Shell.Theme.fontFamily; font.pixelSize: 12
    }
    Rectangle {
      objectName: "shortcutsEditorDelete"
      x: 30; anchors.verticalCenter: parent.verticalCenter
      visible: !!root.editing && Shortcuts.State.error === ""
      width: 84; height: 40; radius: 8
      color: deleteHover.hovered ? "#3a2622" : "transparent"
      border.width: 1; border.color: "#4a4a4a"
      Accessible.role: Accessible.Button
      Accessible.name: "Delete shortcut"
      Accessible.onPressAction: root.remove()
      Text {
        anchors.centerIn: parent; text: "Delete"
        color: "#ffb4ab"
        font.family: Shell.Theme.fontFamily; font.pixelSize: 13
      }
      HoverHandler { id: deleteHover; cursorShape: Qt.PointingHandCursor }
      TapHandler { onTapped: root.remove() }
    }
    Row {
      x: parent.width - width - 30; anchors.verticalCenter: parent.verticalCenter
      spacing: 8
      Rectangle {
        objectName: "shortcutsEditorCancel"
        width: 84; height: 40; radius: 8
        color: cancelHover.hovered ? "#303030" : "transparent"
        border.width: 1; border.color: "#4a4a4a"
        Accessible.role: Accessible.Button
        Accessible.name: "Cancel"
        Accessible.onPressAction: Settings.State.back()
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
        width: 120; height: 40; radius: 8
        color: root.valid ? "#cba6f7" : "#3a2f45"
        opacity: root.valid && !root.saving ? 1 : 0.45
        Accessible.role: Accessible.Button
        Accessible.name: saveText.text
        Accessible.onPressAction: root.save()
        Text {
          id: saveText
          anchors.centerIn: parent
          text: root.editing ? "Save changes" : "Add shortcut"
          color: root.valid ? "#1d1d1d" : "white"
          opacity: root.valid ? 1 : 0.5
          font.family: Shell.Theme.fontFamily
          font.weight: Font.DemiBold; font.pixelSize: 13
        }
        HoverHandler { cursorShape: Qt.PointingHandCursor }
        TapHandler { onTapped: root.save() }
      }
    }
  }
}
