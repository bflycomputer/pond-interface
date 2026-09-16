import QtQuick
import ".."

Item {
  id: root
  property alias text: field.text
  property string placeholderText: "Enter password"
  property bool revealed: false
  signal accepted
  signal editingStarted

  implicitWidth: PanelStyle.fieldWidth
  implicitHeight: PanelStyle.fieldHeight

  Field {
    id: field
    anchors.fill: parent
    placeholderText: root.placeholderText
    password: true
    revealed: root.revealed
    rightPadding: 52
    onAccepted: root.accepted()
    onEditingStarted: root.editingStarted()
  }

  Rectangle {
    id: eyeButton
    x: 240
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

  function activateEditor(reason) {
    field.activateEditor(reason);
  }
}
