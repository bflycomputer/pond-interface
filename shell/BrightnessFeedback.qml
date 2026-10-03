import QtQuick
import Quickshell
import Quickshell.Wayland
import "settings/appearance" as Appearance

Item {
  id: root
  required property var screen
  required property real collapseProgress
  required property real expandedBottomMargin
  property real value: 0
  readonly property bool collapsed: collapseProgress >= 0.56
  width: Theme.sidebarCardExpandedWidth
  height: 38 // The sidebar's 6px spacing completes the 8px gap below the card.
  visible: feedback.active && !collapsed

  Connections {
    target: Appearance.State
    function onKeyboardBrightnessChanged(outputName, value) {
      if (outputName !== root.screen.name) return;
      root.value = value;
      feedback.active = true;
      dismissTimer.restart();
    }
  }
  Timer { id: dismissTimer; interval: 1200; onTriggered: feedback.active = false }

  component Indicator: Card {
    id: card
    required property real value
    width: Theme.sidebarCardExpandedWidth
    height: 36
    radius: PanelStyle.radius
    classicColor: PanelStyle.surface
    Accessible.role: Accessible.ProgressBar
    Accessible.name: "Brightness " + Math.round(value * 100) + "%"

    Row {
      anchors.centerIn: parent
      spacing: 9
      Image {
        width: 16
        height: 16
        source: "assets/brightness.svg"
        sourceSize: Qt.size(32, 32)
      }
      Row {
        anchors.verticalCenter: parent.verticalCenter
        spacing: 5
        Repeater {
          model: 10
          Rectangle {
            required property int index
            width: 6
            height: 6
            radius: 3
            color: index < Math.round(Theme.clamp01(card.value) * 10) ? "white"
                : Theme.daylight ? Theme.sidebarInnerOutline : PanelStyle.border
          }
        }
      }
    }
  }

  LazyLoader {
    id: feedback
    PanelWindow {
      screen: root.screen
      color: "transparent"
      BackgroundEffect.blurRegion: Theme.daylight ? indicator.blurRegion : null
      implicitWidth: Theme.sidebarCardExpandedWidth + (root.collapsed ? 134 : 0)
      implicitHeight: root.collapsed ? 67 + 36 + 40 : 36
      anchors { left: true; bottom: true }
      margins.left: root.collapsed ? Math.round((screen.width + Theme.sidebarOuterMargin
          + Theme.sidebarCardCollapsedWidth - implicitWidth) / 2) : Theme.sidebarOuterMargin
      margins.bottom: root.collapsed ? 0 : Math.round(root.expandedBottomMargin)
      WlrLayershell.layer: WlrLayer.Overlay
      WlrLayershell.namespace: "pond-brightness"
      WlrLayershell.exclusionMode: ExclusionMode.Ignore
      mask: Region {}

      Shadow {
        visible: root.collapsed
        anchors.fill: indicator
        cornerRadius: PanelStyle.radius
        shadows: PanelStyle.controlShadows
      }
      Indicator {
        id: indicator
        x: root.collapsed ? 67 : 0
        y: root.collapsed ? 67 : 0
        value: root.value
      }
    }
  }
}
