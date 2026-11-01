import QtQuick
Rectangle {
  id: root
  property string text: ""
  property bool interactive: true
  signal clicked
  implicitWidth: 146
  implicitHeight: 40
  radius: 10
  color: pointer.containsMouse ? PanelStyle.controlHover : PanelStyle.controlFill
  opacity: interactive ? 1 : 0.4
  Text {
    anchors.centerIn: parent
    text: root.text
    color: "white"
    opacity: 0.8
    font.family: Theme.fontFamily
    font.weight: Font.Medium
    font.pixelSize: 13
  }
  MouseArea {
    id: pointer
    anchors.fill: parent
    enabled: root.interactive
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: root.clicked()
  }
}
