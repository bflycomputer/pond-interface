import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import "." as Battery
import ".." as Shell

PanelWindow {
  id: root
  required property var bar
  required property var above
  readonly property bool fullscreen: bar.fullscreenCovered

  screen: bar.screen
  visible: Battery.State.alert > 0 && (fullscreen || bar.collapseProgress > 0.42)
  color: "transparent"
  implicitWidth: card.width + 68
  implicitHeight: card.height + (fullscreen ? 54 : 145)
  mask: Region { item: card }

  anchors { left: true; top: !root.fullscreen; bottom: root.fullscreen }
  margins {
    left: Math.round(fullscreen ? (screen.width - card.width) / 2
        : Shell.Theme.sidebarOuterMargin + bar.cardWidth + 20) - card.x
    top: (above.visible ? 20 + above.cardHeight : 20) - card.y
  }

  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.namespace: "pond-battery-alert-" + (screen ? screen.name : "unknown")
  WlrLayershell.exclusionMode: ExclusionMode.Ignore

  Item {
    id: card
    x: 34
    y: 14
    width: root.fullscreen ? Math.ceil(label.implicitWidth) + 46 : 140
    height: root.fullscreen ? 32 : 34

    Shell.Shadow {
      anchors.fill: parent
      cornerRadius: surface.radius
      shadows: Shell.PanelStyle.controlShadows
    }

    Rectangle {
      id: surface
      anchors.fill: parent
      radius: root.fullscreen ? 4 : 8
      color: Battery.State.lowSurface
    }

    FontMetrics { id: metrics; font: label.font }

    Text {
      id: label
      x: 12
      y: (parent.height - metrics.capitalHeight) / 2 + metrics.capitalHeight - baselineOffset
      text: "Battery at " + Battery.State.level + "%"
      color: Battery.State.lowColor
      font.family: Shell.Theme.fontFamily
      font.weight: Font.Medium
      font.pixelSize: 13
    }

    Rectangle {
      anchors.fill: dismiss
      radius: root.fullscreen ? 2 : 4
      color: dismiss.hovered ? Qt.alpha(Battery.State.lowColor, 0.1) : "transparent"
    }

    Shell.IconButton {
      id: dismiss
      x: parent.width - (root.fullscreen ? 28 : 29)
      y: (parent.height - 24) / 2
      iconSource: Qt.resolvedUrl("../assets/battery/dismiss.svg")
      iconWidth: 24
      iconHeight: 24
      restingOpacity: root.fullscreen ? 1 : 0.3
      animateGlyphOpacity: false
      layer.enabled: true
      layer.effect: MultiEffect { colorization: 1; colorizationColor: Battery.State.lowColor }
      onClicked: Battery.State.alert = 0
      Accessible.role: Accessible.Button
      Accessible.name: "Dismiss"
      Accessible.onPressAction: Battery.State.alert = 0
    }
  }
}
