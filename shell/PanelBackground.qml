import QtQuick
import Quickshell

Rectangle {
  id: root
  // Stacked pages use the surface and border painted by CardLayer.
  property bool stacked: false
  property Gradient fill: PanelStyle.panelGradient
  readonly property Region blurRegion: Region {
    item: root
    radius: root.radius
  }
  color: stacked || fill ? "transparent" : PanelStyle.panelSurface
  radius: PanelStyle.radius
  border.color: PanelStyle.panelBorder
  border.width: stacked || Theme.translucent ? 0 : 1
  antialiasing: true
  clip: true
  GradientFill { fill: root.stacked ? null : root.fill }
  PanelBorder { visible: Theme.translucent && !root.stacked; radius: root.radius }
}
