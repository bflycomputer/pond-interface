import QtQuick
import ".."

Rectangle {
  id: root
  property alias text: editor.text
  property string placeholderText: ""
  property bool password: false
  property bool revealed: false
  property real rightPadding: password ? 52 : 14
  property bool readOnly: false
  property bool highlighted: false
  signal accepted

  readonly property bool hovered: fieldHover.hovered
  readonly property bool focused: editor.activeFocus

  implicitWidth: PanelStyle.fieldWidth
  implicitHeight: PanelStyle.fieldHeight
  radius: PanelStyle.rowRadius
  color: focused || hovered || highlighted
      ? PanelStyle.pressed : PanelStyle.hover
  border.width: focused ? 0.5 : 0
  border.color: PanelStyle.accent
  antialiasing: true

  Behavior on color {
    ColorAnimation { duration: PanelStyle.controlDuration }
  }

  Text {
    x: 14
    anchors.verticalCenter: parent.verticalCenter
    width: parent.width - x - root.rightPadding
    text: root.placeholderText
    visible: editor.text.length === 0
    color: "white"
    opacity: 0.5
    font.family: Theme.fontFamily
    font.weight: Font.Medium
    font.pixelSize: 13
  }

  TextInput {
    id: editor
    x: 14
    anchors.verticalCenter: parent.verticalCenter
    width: parent.width - x - root.rightPadding
    color: root.password && !root.revealed
        ? PanelStyle.accent : "white"
    selectionColor: PanelStyle.accentText
    selectedTextColor: "white"
    font.family: Theme.fontFamily
    font.weight: Font.Medium
    font.pixelSize: root.password && !root.revealed ? 12 : 13
    font.letterSpacing: root.password && !root.revealed ? 2 : 0
    echoMode: root.password && !root.revealed
        ? TextInput.Password : TextInput.Normal
    passwordCharacter: "■"
    readOnly: root.readOnly
    activeFocusOnTab: true
    clip: true
    onAccepted: root.accepted()
  }

  HoverHandler { id: fieldHover; cursorShape: Qt.IBeamCursor }
  TapHandler {
    onTapped: editor.forceActiveFocus(Qt.MouseFocusReason)
  }

  Rectangle {
    id: eyeButton
    visible: root.password
    x: root.width - 36
    y: 8
    width: 28
    height: 28
    radius: 4
    z: 2
    color: eyePointer.containsMouse ? PanelStyle.pressed
        : Qt.rgba(48 / 255, 48 / 255, 48 / 255, 0)

    Behavior on color {
      ColorAnimation { duration: PanelStyle.controlDuration }
    }

    Image {
      anchors.centerIn: parent
      width: 20
      height: 20
      source: root.revealed
          ? Qt.resolvedUrl("../assets/eye-open.svg")
          : Qt.resolvedUrl("../assets/eye-closed.svg")
      opacity: eyePointer.containsMouse ? 1 : 0.7

      Behavior on opacity {
        NumberAnimation { duration: PanelStyle.controlDuration }
      }
    }
    MouseArea {
      id: eyePointer
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: root.revealed = !root.revealed
    }
  }
}
