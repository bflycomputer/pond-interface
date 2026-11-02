import QtQuick
import QtQuick.Effects

Item {
  id: root
  signal clicked
  implicitWidth: 40
  implicitHeight: 40

  Rectangle {
    anchors.fill: parent
    radius: 12
    color: closeHover.hovered ? PanelStyle.closeHover : PanelStyle.closeFill
    border.color: closeHover.hovered ? PanelStyle.closeHoverBorder : PanelStyle.closeBorder
    border.width: Theme.translucent && !closeHover.hovered ? 0 : 1
    antialiasing: true

    PanelBorder {
      visible: Theme.translucent && !closeHover.hovered
      radius: 12
      color: PanelStyle.closeBorder
    }

    Image {
      anchors.centerIn: parent
      width: 20
      height: 20
      source: Qt.resolvedUrl("assets/wifi/close.svg")
      layer.enabled: Theme.translucent && closeHover.hovered
      layer.effect: MultiEffect { colorization: 1; colorizationColor: Theme.colors.closeHoverGlyph }
    }
  }

  HoverHandler { id: closeHover; cursorShape: Qt.PointingHandCursor }
  TapHandler { onTapped: root.clicked() }
}
