import QtQuick

Item {
  id: root
  signal clicked
  implicitWidth: 40
  implicitHeight: 40

  Rectangle {
    anchors.fill: parent
    radius: 12
    color: closeHover.hovered ? PanelStyle.pressed : PanelStyle.hover
    border.color: PanelStyle.border
    border.width: 0.5
    antialiasing: true

    Image {
      anchors.centerIn: parent
      width: 20
      height: 20
      source: Qt.resolvedUrl("assets/wifi/close.svg")
    }
  }

  HoverHandler { id: closeHover; cursorShape: Qt.PointingHandCursor }
  TapHandler { onTapped: root.clicked() }
}
