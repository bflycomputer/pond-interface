import QtQuick
import Quickshell
import Quickshell.Wayland

// Full-screen click-away surface for the settings card stacks. Layer-shell
// surfaces on the same layer are not guaranteed to keep creation order for
// input. Exclude the sidebar's input region so its controls receive events
// while empty background areas share this window's click-away behavior.
PanelWindow {
  id: root

  required property var bar

  screen: bar.screen
  visible: bar.panelOpen
  color: "transparent"

  anchors {
    left: true
    right: true
    top: true
    bottom: true
  }

  WlrLayershell.layer: WlrLayer.Top
  WlrLayershell.namespace: "pond-controls-dismiss-"
      + (screen ? screen.name : "unknown")
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
  WlrLayershell.exclusionMode: ExclusionMode.Ignore

  mask: Region {
    intersection: Intersection.Subtract
    regions: [root.bar.mask]
  }

  MouseArea {
    anchors.fill: parent
    acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
    onClicked: root.bar.dismissPanels()
  }
}
