import QtQuick
import Quickshell
import Quickshell.Wayland
import "calendar" as Calendar
import "media" as Media
import "nirimap" as Nirimap
import "notifications" as Notifications

PanelWindow {
  id: root
  required property bool expanded
  property bool calendarOpen: false
  property real collapseProgress: expanded ? 0 : 1
  signal toggleRequested
  readonly property real cardWidth: Theme.lerp(Theme.sidebarCardExpandedWidth,
      Theme.sidebarCardCollapsedWidth, collapseProgress)
  readonly property real notificationCardCenterY: mainStack.y + notificationCard.y + 24
  property real siblingOpacity: Notifications.State.panelOpen
      && Notifications.State.panelOutputName === screen.name ? 0.6 : 1

  color: "transparent"
  // Keep compositor resizes out of the card animation; only the input area shrinks.
  implicitWidth: Theme.sidebarOuterMargin + Theme.sidebarCardExpandedWidth + 8
  mask: Region {
    width: Math.ceil(Theme.sidebarOuterMargin + Math.max(root.cardWidth,
        workspacesCard.width, mediaCard.width, controls.width) + 8)
    height: root.height
  }
  anchors { left: true; top: true; bottom: true }
  WlrLayershell.layer: WlrLayer.Top
  WlrLayershell.namespace: "pond-sidebar"
  WlrLayershell.keyboardFocus: workspacesCard.dragSession.active
      ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
  WlrLayershell.exclusionMode: ExclusionMode.Normal
  exclusiveZone: Theme.sidebarOuterMargin + (expanded
      ? Theme.sidebarCardExpandedWidth : Theme.sidebarCardCollapsedWidth)
  Behavior on collapseProgress { Motion {} }
  Behavior on siblingOpacity { HoverAnimation { duration: 180 } }

  Column {
    id: mainStack
    x: Theme.sidebarOuterMargin
    y: Theme.sidebarOuterMargin
    spacing: Theme.sidebarCardGap

    Calendar.Clock {
      id: timeCard
      width: root.cardWidth
      collapseProgress: root.collapseProgress
      opacity: root.siblingOpacity
      onClicked: {
        Notifications.State.closePanel();
        root.calendarOpen = !root.calendarOpen;
      }
    }

    Nirimap.Map {
      id: workspacesCard
      screen: root.screen
      collapseProgress: root.collapseProgress
      maximumHeight: Math.max(64,
          bottomStack.y - Theme.sidebarCardGap - mainStack.y
          - timeCard.height - mediaCard.height - notificationCard.height
          - Theme.sidebarCardGap * (mediaCard.visible ? 3 : 2))
      opacity: root.siblingOpacity
      onFocusRequested: index => NiriMsg.focusWorkspace(index)
      onWindowRequested: windowId => NiriMsg.focusWindow(windowId)
    }

    Media.Player {
      id: mediaCard
      collapseProgress: root.collapseProgress
      opacity: root.siblingOpacity
    }

    Notifications.SidebarCard {
      id: notificationCard
      width: root.cardWidth
      collapseProgress: root.collapseProgress
      onPanelRequested: Notifications.State.togglePanel(root.screen.name)
    }
  }

  Item {
    id: bottomStack
    x: Theme.sidebarOuterMargin
    anchors.bottom: parent.bottom
    anchors.bottomMargin: Theme.sidebarOuterMargin
    width: controls.width
    height: controls.height
    opacity: root.siblingOpacity
    BottomControls {
      id: controls
      collapseProgress: root.collapseProgress
      onCollapseClicked: root.toggleRequested()
    }
  }
}
