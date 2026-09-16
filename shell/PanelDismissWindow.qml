import QtQuick
import Quickshell
import Quickshell.Wayland

// Full-screen click-away surface for the settings card stacks. Layer-shell
// surfaces on the same layer are not guaranteed to keep creation order for
// input. Explicitly cut the entire sidebar surface out of this window's input
// region so its card controls always receive pointer events.
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
    x: Math.min(root.width, root.bar.implicitWidth)
    width: root.width - x
    height: root.height
  }

  MouseArea {
    anchors.fill: parent
    acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
    onClicked: root.bar.dismissPanels()
  }
}
