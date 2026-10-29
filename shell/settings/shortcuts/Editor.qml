pragma ComponentBehavior: Bound

import QtQuick
import ".." as Settings
import "." as Shortcuts
import "../.." as Shell

Settings.Modal {
  id: root
  objectName: "shortcutsEditor"
  title: Shortcuts.State.editing ? "Edit shortcut" : "New shortcut"
  bodyTop: 92
  contentHeight: form.height + 76
  onBackRequested: Settings.State.back()
  Keys.onEscapePressed: Settings.State.back()

  // Chord capture happens inside the combination box: press-and-hold shows
  // modifier keycaps live, a non-modifier key finalizes, Escape cancels.
  property string name: Shortcuts.State.editing ? (Shortcuts.State.editing.title || "") : ""
  property string selectedAction: Shortcuts.State.editing ? Shortcuts.State.editing.action : ""
  readonly property bool customMode: selectedAction === ""
  property string customCommand: ""
  property bool shellCommand: false
  property bool repeatAllowed: false
  property bool recording: false
  property var stagedMods: []
  property var chordParts: Shortcuts.State.editing
      ? String(Shortcuts.State.editing.key).split("+") : []
  property string hint: ""

  readonly property string order: "Mod|Shift|Ctrl|Alt|Super"
  readonly property string chord: root.chordParts.join("+")
  readonly property string actionValue: {
    if (root.customMode) {
      const command = root.customCommand.trim();
      if (command === "") return "";
      return root.shellCommand
          ? "spawn-sh \"" + command.replace(/\"/g, "\\\"") + "\""
          : "spawn " + root.splitCommand(command);
    }
    return root.selectedAction;
  }
  readonly property bool conflict: {
    if (root.chord === "") return false;
    const original = Shortcuts.State.editing
        ? root.canonical(Shortcuts.State.editing.key) : "";
    return Shortcuts.State.binds.some(bind =>
        root.canonical(bind.key) === root.canonical(root.chord)
        && root.canonical(bind.key) !== original);
  }
  readonly property bool valid: root.chord !== "" && root.actionValue !== "" && !root.conflict

  function canonical(key) {
    const parts = String(key).split("+"), mods = [];
    let chord = "";
    for (const part of parts) {
      if (["Mod", "Shift", "Ctrl", "Alt", "Super"].indexOf(part) >= 0) mods.push(part);
      else if (chord !== "") return "";
      else chord = part;
    }
    mods.sort((left, right) => root.order.indexOf(left) - root.order.indexOf(right));
    return mods.join("+") + "+" + chord;
  }

  function splitCommand(command) {
    const tokens = command.match(/"([^"]*)"|\S+/g) || [];
    return tokens.map(token =>
        token.startsWith("\"") ? token : JSON.stringify(token)).join(" ");
  }

  function save() {
    if (!root.valid) return;
    const flags = {};
    if (root.repeatAllowed) flags.repeat = true;
    Shortcuts.State.saveShortcut(
        Shortcuts.State.editing ? Shortcuts.State.editing.key : "",
        {
          key: root.chord,
          title: root.name.trim(),
          flags: flags,
          action: root.actionValue
        },
        () => Settings.State.back());
  }

  function remove() {
    if (!Shortcuts.State.editing) return;
    Shortcuts.State.removeShortcut(Shortcuts.State.editing.key,
        () => Settings.State.back());
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

  function capture(event) {
    const key = root.keySym(event);
    if (key === "") return;
    root.chordParts = root.stagedMods.slice().sort((left, right) =>
        root.order.indexOf(left) - root.order.indexOf(right)).concat([key]);
    root.recording = false;
    root.stagedMods = [];
    root.hint = "";
  }

  function keySym(event) {
    const key = event.key;
    if (key >= Qt.Key_A && key <= Qt.Key_Z) return String.fromCharCode(Qt.Key_A + (key - Qt.Key_A));
    if (key >= Qt.Key_0 && key <= Qt.Key_9) return String.fromCharCode(Qt.Key_0 + (key - Qt.Key_0));
    if (key >= Qt.Key_F1 && key <= Qt.Key_F35) return "F" + (key - Qt.Key_F1 + 1);
    const names = {};
    names[Qt.Key_Space] = "Space"; names[Qt.Key_Tab] = "Tab";
    names[Qt.Key_Return] = "Return"; names[Qt.Key_Enter] = "Return";
    names[Qt.Key_Backspace] = "Backspace"; names[Qt.Key_Delete] = "Delete";
    names[Qt.Key_Insert] = "Insert"; names[Qt.Key_Home] = "Home"; names[Qt.Key_End] = "End";
    names[Qt.Key_PageUp] = "Page_Up"; names[Qt.Key_PageDown] = "Page_Down";
    names[Qt.Key_Left] = "Left"; names[Qt.Key_Right] = "Right";
    names[Qt.Key_Up] = "Up"; names[Qt.Key_Down] = "Down";
    names[Qt.Key_Minus] = "Minus"; names[Qt.Key_Equal] = "Equal"; names[Qt.Key_Slash] = "Slash";
    names[Qt.Key_Comma] = "Comma"; names[Qt.Key_Period] = "Period";
    names[Qt.Key_Semicolon] = "Semicolon"; names[Qt.Key_Apostrophe] = "Apostrophe";
    names[Qt.Key_BracketLeft] = "BracketLeft"; names[Qt.Key_BracketRight] = "BracketRight";
    names[Qt.Key_Backslash] = "Backslash"; names[Qt.Key_QuoteLeft] = "Grave";
    names[Qt.Key_Print] = "Print";
    names[Qt.Key_MediaPlay] = "XF86AudioPlay"; names[Qt.Key_MediaPause] = "XF86AudioPause";
    names[Qt.Key_MediaStop] = "XF86AudioStop"; names[Qt.Key_MediaNext] = "XF86AudioNext";
    names[Qt.Key_MediaPrevious] = "XF86AudioPrev";
    names[Qt.Key_VolumeUp] = "XF86AudioRaiseVolume"; names[Qt.Key_VolumeDown] = "XF86AudioLowerVolume";
    names[Qt.Key_VolumeMute] = "XF86AudioMute"; names[Qt.Key_MicMute] = "XF86AudioMicMute";
    const name = names[key];
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

      Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape) event.accepted = false;
        else if (!root.recording) event.accepted = false;
        else if (event.key === Qt.Key_Return || event.key === Qt.Key_Tab) event.accepted = false;
        else { root.capture(event); event.accepted = true; }
      }
      Keys.onReleased: event => {
        if (root.recording) root.stagedMods = root.allMods(event.modifiers);
        event.accepted = true;
      }

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
      visible: root.hint !== "" || root.conflict
      text: root.conflict ? "That combination is already in use." : root.hint
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
            readonly property bool chosen: root.actionValue === modelData.action
            width: section.width; height: 44; radius: 12
            color: hover.hovered || chosen ? "#262626" : "transparent"
            Text {
              x: 20; anchors.verticalCenter: parent.verticalCenter
              text: action.modelData.label; color: "white"; opacity: action.chosen ? 1 : 0.7
              font.family: Shell.Theme.fontFamily; font.pixelSize: 15
            }
            Text {
              anchors.right: parent.right; anchors.rightMargin: 20
              anchors.verticalCenter: parent.verticalCenter
              width: Math.min(180, implicitWidth); elide: Text.ElideMiddle
              text: action.modelData.action.replace(/;$/, "")
              color: "white"; opacity: 0.25
              font.family: "JetBrains Mono"; font.pixelSize: 12
            }
            Image {
              visible: action.chosen
              x: parent.width - 92
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
      visible: Shortcuts.State.editing
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
      opacity: root.valid || saveHover.hovered ? 1 : 0.45
      Text {
        anchors.centerIn: parent
        text: Shortcuts.State.editing ? "Save changes" : "Add shortcut"
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
