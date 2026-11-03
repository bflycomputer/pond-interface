import QtQuick
import Quickshell

Rectangle {
  id: root
  // The stack paints one translucent surface; a second on top would darken it.
  property bool stacked: false
  property Gradient fill: PanelStyle.panelGradient
  readonly property Region blurRegion: Region {
    item: root
    radius: root.radius
  }
  color: stacked && Theme.translucent || fill ? "transparent" : PanelStyle.panelSurface
  radius: PanelStyle.radius
  border.color: PanelStyle.panelBorder
  border.width: Theme.translucent ? 0 : 1
  antialiasing: true
  clip: true
  GradientFill { fill: root.stacked && Theme.translucent ? null : root.fill }
  PanelBorder { visible: Theme.translucent && !root.stacked; radius: root.radius }
}
