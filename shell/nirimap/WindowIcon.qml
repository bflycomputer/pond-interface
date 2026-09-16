import QtQuick
import QtQuick.Effects
import Quickshell.Widgets
import ".." as Shell

// One live window marker. The same primitive scales between the 40px
// expanded rail and the 32px collapsed stack while retaining app activation
// across both layouts.
Item {
  id: root

  property var windowData: ({})
  property real controlSize: Shell.Theme.workspaceControlSize
  property bool interactive: true
  property bool lifted: false
  signal activated(var windowId)

  readonly property bool hovered: pointer.containsMouse

  implicitWidth: controlSize
  implicitHeight: controlSize

  Rectangle {
    anchors.fill: parent
    radius: width / 2
    antialiasing: true
    // Fade alpha without interpolating the fill through transparent black.
    color: root.lifted ? "#292929" : root.hovered ? Shell.Theme.sidebarControlHover
        : Qt.rgba(Shell.Theme.sidebarControlHover.r, Shell.Theme.sidebarControlHover.g,
                  Shell.Theme.sidebarControlHover.b, 0)
    border.color: root.lifted ? "#CBA6F7" : Shell.Theme.sidebarInnerOutline
    border.width: root.hovered ? 0 : Shell.Theme.sidebarStrokeWidth
    layer.enabled: root.lifted
    layer.effect: MultiEffect {
      shadowEnabled: true
      shadowBlur: 0.5
      blurMax: 10
      shadowOpacity: 0.4
      shadowHorizontalOffset: 2
      shadowVerticalOffset: 5
    }

    Behavior on color {
      ColorAnimation {
        duration: Shell.Theme.sidebarHoverDuration
        easing.type: Easing.OutCubic
      }
    }
  }

  IconImage {
    anchors.centerIn: parent
    visible: (root.windowData.iconSource || "") !== ""
    width: Shell.Theme.workspaceIconSize
    height: Shell.Theme.workspaceIconSize
    source: root.windowData.iconSource || ""
    asynchronous: true
    smooth: true
    opacity: root.hovered || root.lifted ? 1.0 : 0.9

    Behavior on opacity { Shell.HoverAnimation {} }
  }

  MouseArea {
    id: pointer
    anchors.fill: parent
    enabled: root.interactive
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton
    cursorShape: Qt.PointingHandCursor
    onClicked: {
      if (root.windowData.winId !== undefined)
        root.activated(root.windowData.winId);
    }
  }
}
