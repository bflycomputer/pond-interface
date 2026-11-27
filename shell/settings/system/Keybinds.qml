pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import ".." as Settings
import "../.." as Shell

Settings.Modal {
  id: root
  objectName: "keybindsPanel"
  title: "Keybinds"; closeLabel: "Back to System"; bodyTop: 143
  implicitHeight: Math.min(676, availableHeight)
  property var binds: []
  property var names: ({})
  property var target: null
  property var keys: []
  property string conflict
  property bool resetting: false
  readonly property bool recording: !!target && !conflict
  readonly property bool popup: !!target || resetting
  readonly property bool complete: keys.length > 0 && !modifier(keys[keys.length - 1])
  readonly property string query: search.input.text.trim().toLowerCase()
  readonly property var rows: {
    const result = [];
    for (const bind of binds) {
      if (query && !bind.label.toLowerCase().includes(query)) continue;
      if (!result.length || result[result.length - 1].section !== bind.section) result.push({header: true, section: bind.section});
      result.push(bind);
    }
    return result;
  }
  onBackRequested: Settings.State.back()
  Keys.onEscapePressed: { if (search.input.text) search.input.clear(); else Settings.State.back(); }
  Component.onCompleted: run(["load"])

  function modifier(name) { return ["Mod", "Ctrl", "Shift", "Alt"].includes(name); }
  function strong(text) {
    return `<font color="${Shell.Theme.colors.text}">${text.replace(/&/g, "&amp;").replace(/</g, "&lt;")}</font>`;
  }
  function run(args) {
    if (helper.running) return;
    helper.command = ["python3", decodeURIComponent(Qt.resolvedUrl("keybinds.py").toString().replace(/^file:\/\//, ""))].concat(args);
    helper.running = true;
  }
  function accept(text) {
    let result = {};
    try { result = JSON.parse(text); } catch (e) {}
    if (result.conflict) { conflict = result.conflict; return; }
    if (result.binds) { binds = result.binds; names = result.names; }
    dismiss();
  }
  function record(bind) {
    keys = [];
    target = bind;
    capture.forceActiveFocus();
  }
  function confirmReset() {
    resetting = true;
    capture.forceActiveFocus();
  }
  function press(code) {
    const name = names[code];
    if (!name) return;
    if (complete) keys = [name];
    else if (!keys.includes(name) && !(keys.length === 3 && modifier(name))) keys = keys.concat(name);
  }
  function dismiss() {
    target = null;
    conflict = "";
    resetting = false;
    root.forceActiveFocus();
  }

  Process {
    id: helper
    stdout: StdioCollector { onStreamFinished: root.accept(text) }
  }
  ShortcutInhibitor { window: root.QsWindow.window; enabled: root.recording }

  ListView {
    id: list
    objectName: "keybindsList"
    x: 16; width: root.width - 32; height: root.scrollItem.height - 4
    bottomMargin: 12; clip: true
    boundsBehavior: Flickable.StopAtBounds
    enabled: !root.popup
    model: root.rows
    Shell.ScrollWheel { view: list }
    delegate: Item {
      id: row
      required property var modelData
      required property int index
      width: list.width; height: modelData.header ? (index ? 60 : 50) : 56
      Text {
        visible: !!row.modelData.header
        x: 20; anchors.baseline: parent.bottom; anchors.baselineOffset: -16
        text: row.modelData.section; color: Shell.Theme.colors.text
        font.family: Shell.Theme.titleFontFamily; font.pixelSize: 20
      }
      Rectangle {
        visible: !row.modelData.header
        anchors.fill: parent; radius: 12
        color: hover.hovered ? Shell.PanelStyle.rowHover : "transparent"
        Accessible.role: Accessible.Button
        Accessible.name: (row.modelData.label || "") + ", " + (row.modelData.keys || []).join("+")
        Accessible.onPressAction: root.record(row.modelData)
        Text {
          x: 20; width: keys.x - 40; anchors.verticalCenter: parent.verticalCenter
          text: row.modelData.label || ""; elide: Text.ElideRight
          color: Shell.Theme.colors.text; opacity: 0.7
          font.family: Shell.Theme.fontFamily; font.pixelSize: 15
        }
        Row {
          id: keys
          anchors.right: parent.right; anchors.rightMargin: 8; anchors.verticalCenter: parent.verticalCenter
          spacing: 5
          Repeater {
            model: row.modelData.keys || []
            delegate: Key { required property string modelData; name: modelData }
          }
        }
        HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
        TapHandler { onTapped: root.record(row.modelData) }
      }
    }
  }

  component Card: Rectangle {
    anchors.centerIn: parent
    radius: 16; color: Settings.Style.card; border.color: Qt.rgba(1, 1, 1, 0.15)
    Shell.Shadow { anchors.fill: parent; z: -1; cornerRadius: 16; shadows: Shell.PanelStyle.controlShadows }
  }
  component Pill: Rectangle {
    id: pill
    property string text
    property bool primary: false
    signal clicked
    height: 48; radius: 24
    color: primary ? Shell.PanelStyle.accent : Shell.PanelStyle.controlFill
    Accessible.role: Accessible.Button
    Accessible.name: text
    Accessible.onPressAction: clicked()
    Text {
      anchors.centerIn: parent
      text: pill.text; color: pill.primary ? Shell.PanelStyle.accentText : Shell.Theme.colors.text
      font.family: Shell.Theme.fontFamily; font.weight: Font.Medium; font.pixelSize: 15
    }
    HoverHandler { cursorShape: Qt.PointingHandCursor }
    TapHandler { onTapped: pill.clicked() }
  }
  component Question: Text {
    x: 25; anchors.baseline: parent.top
    color: Shell.Theme.colors.text
    wrapMode: Text.WordWrap; lineHeight: 28; lineHeightMode: Text.FixedHeight
    font.family: Shell.Theme.titleFontFamily; font.pixelSize: 20
  }

  overlay: [
    Search { id: search; placeholder: "Search keybinds"; enabled: !root.popup },
    Settings.ModalScrollBar { view: list; enabled: !root.popup },
    Rectangle {
      objectName: "keybindsReset"
      x: root.width - 106; y: 21; width: 76; height: 40; radius: 8
      enabled: !root.popup
      color: resetHover.hovered ? Shell.PanelStyle.rowHover : "transparent"
      border.width: resetHover.hovered ? 0 : 1; border.color: Shell.PanelStyle.outline
      Accessible.role: Accessible.Button
      Accessible.name: "Reset keybinds"
      Accessible.onPressAction: root.confirmReset()
      Text {
        anchors.centerIn: parent
        text: "Reset"; color: Shell.Theme.colors.text; opacity: resetHover.hovered ? 1 : 0.5
        font.family: Shell.Theme.fontFamily; font.weight: Font.DemiBold
        font.pixelSize: 10; font.letterSpacing: 0.1
      }
      HoverHandler { id: resetHover; cursorShape: Qt.PointingHandCursor }
      TapHandler { onTapped: root.confirmReset() }
    },
    Rectangle {
      anchors.fill: parent; radius: root.radius
      visible: root.popup
      color: Qt.alpha(Shell.Theme.colors.modalSurface, 0.8)
    },
    Item {
      id: capture
      Keys.onPressed: event => {
        event.accepted = true;
        if (!root.recording) { if (event.key === Qt.Key_Escape) root.dismiss(); }
        else if (!event.isAutoRepeat) root.press(event.nativeScanCode);
      }
      Keys.onReleased: event => event.accepted = true
    },
    Card {
      objectName: "keybindRecorder"
      visible: root.recording; width: 400; height: 269
      Rectangle {
        id: dot
        x: 25; y: 25; width: 9; height: 9; radius: 4.5
        color: blink.lit ? border.color : "transparent"; border.color: "#FA6D80"
        Timer {
          id: blink
          property bool lit: true
          running: root.recording; repeat: true; interval: 500
          onTriggered: lit = !lit
        }
      }
      Text {
        x: 40; anchors.baseline: dot.bottom
        text: "Rec"; color: dot.border.color
        font.family: Shell.Theme.fontFamily; font.weight: Font.Medium; font.pixelSize: 13
      }
      Text {
        id: prompt
        x: 25; anchors.baseline: parent.top; anchors.baselineOffset: 61
        text: "Press keys for"; color: Shell.Theme.colors.text; opacity: 0.7
        font.family: Shell.Theme.fontFamily; font.pixelSize: 15
      }
      Text {
        anchors.left: prompt.right; anchors.leftMargin: 4; anchors.baseline: prompt.baseline
        width: parent.width - x - 25
        text: root.target?.label ?? ""; elide: Text.ElideRight
        color: Shell.Theme.colors.text
        font.family: Shell.Theme.fontFamily; font.pixelSize: 15
      }
      Row {
        x: 25; y: 86; spacing: 10
        Repeater {
          model: 4
          delegate: Key {
            id: slot
            required property int index
            large: true
            name: root.keys[index] ?? ""
            active: !root.complete && index === root.keys.length
            empty: index >= root.keys.length && !slot.active
          }
        }
      }
      Pill {
        x: 25; y: 196; width: 48
        Accessible.name: "Cancel"
        onClicked: root.dismiss()
        Image {
          anchors.centerIn: parent
          width: 20; height: 20; sourceSize: Qt.size(40, 40)
          source: Qt.resolvedUrl("../../assets/wifi/close.svg")
        }
      }
      Pill {
        objectName: "keybindDone"
        x: 81; y: 196; width: 294
        primary: true; text: "Done"
        onClicked: { if (root.complete) root.run(["bind", root.target.id, root.keys.join("+")]); else root.dismiss(); }
      }
    },
    Card {
      objectName: "keybindConflict"
      visible: !!root.conflict; width: 400; height: 292
      Row {
        x: 25; y: 25; spacing: 10
        Repeater {
          model: root.keys
          delegate: Key { required property string modelData; large: true; name: modelData }
        }
      }
      Question {
        width: 350; anchors.baselineOffset: 143
        textFormat: Text.StyledText
        color: Qt.alpha(Shell.Theme.colors.text, 0.6)
        text: `This shortcut is being used for ${root.strong(root.conflict)}. Reassign it to ${root.strong(root.target?.label ?? "")}?`
      }
      Pill { x: 25; y: 219; width: 171; text: "Cancel"; onClicked: root.dismiss() }
      Pill {
        objectName: "keybindReassign"
        x: 204; y: 219; width: 171
        primary: true; text: "Reassign"
        onClicked: root.run(["bind", root.target.id, root.keys.join("+"), "force"])
      }
    },
    Card {
      objectName: "keybindResetConfirm"
      visible: root.resetting; width: 344; height: 190
      Question { width: 210; anchors.baselineOffset: 39; text: "Reset all keybinds to their defaults?" }
      Pill { x: 25; y: 117; width: 143; text: "Cancel"; onClicked: root.dismiss() }
      Pill { x: 176; y: 117; width: 143; primary: true; text: "Yes, reset"; onClicked: root.run(["reset"]) }
    }
  ]
}
