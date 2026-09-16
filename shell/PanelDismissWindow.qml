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
  visible: true
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
    x: root.bar && root.bar.panelOpen
        ? Math.max(0, Math.min(root.width, root.bar.implicitWidth)) : 0
    y: 0
    width: root.bar && root.bar.panelOpen
        ? Math.max(0, root.width - x) : 0
    height: root.bar && root.bar.panelOpen ? root.height : 0
  }

  MouseArea {
    anchors.fill: parent
    enabled: root.bar && root.bar.panelOpen
    acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
    onClicked: root.bar.dismissPanels()
  }
}
