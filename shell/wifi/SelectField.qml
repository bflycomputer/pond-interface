import QtQuick
import QtQuick.Controls as Controls
import ".."

Controls.Button {
  id: root
  implicitWidth: PanelStyle.fieldWidth
  implicitHeight: PanelStyle.fieldHeight
  hoverEnabled: true
  focusPolicy: Qt.StrongFocus
  leftPadding: 14
  rightPadding: 44
  Keys.onReturnPressed: clicked()
  Keys.onEnterPressed: clicked()
  HoverHandler { cursorShape: Qt.PointingHandCursor }

  background: Rectangle {
    radius: PanelStyle.rowRadius
    color: root.hovered || root.activeFocus ? PanelStyle.pressed : PanelStyle.hover
    Behavior on color { ColorAnimation { duration: PanelStyle.controlDuration } }
  }
  contentItem: Text {
    text: root.text
    verticalAlignment: Text.AlignVCenter
    elide: Text.ElideRight
    color: "white"
    font.family: Theme.fontFamily
    font.weight: Font.Medium
    font.pixelSize: 13
  }
  Image {
    anchors.right: parent.right
    anchors.rightMargin: 14
    anchors.verticalCenter: parent.verticalCenter
    width: 16
    height: 16
    source: Qt.resolvedUrl("../assets/wifi/chevron.svg")
  }
}
