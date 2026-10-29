import QtQuick

// A titled card shown above the bottom controls: volume, brightness or network.
Card {
  id: root
  default property alias body: body.data
  property string title: ""
  width: Theme.sidebarCardExpandedWidth
  height: 56
  radius: PanelStyle.radius
  // Opaque in every theme so the card reads over any window.
  color: PanelStyle.surface

  Text {
    x: 14
    y: 9
    width: parent.width - 28
    text: root.title
    elide: Text.ElideRight
    color: "white"
    opacity: 0.6
    font.family: Theme.fontFamily
    font.weight: Font.Medium
    font.pixelSize: 12
  }

  Item {
    id: body
    x: 12
    y: 22
    width: parent.width - 24
    height: 32
  }
}
