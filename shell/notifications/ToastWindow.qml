import QtQuick
import Quickshell
import Quickshell.Wayland
import "." as Notifications
import ".." as Shell

// Collapsed-sidebar arrival surface. Its left edge tracks the animated
// sidebar edge, so it never temporarily overlaps and then jumps with the
// compositor's work-area change.
PanelWindow {
  id: root

  required property var bar

  readonly property string outputName: bar && bar.screen ? bar.screen.name : ""
  readonly property bool outputMatches: Notifications.State.transientOutputName === ""
      || Notifications.State.transientOutputName === outputName
  readonly property bool requested: outputMatches
      && Notifications.State.transientVisible
      && bar.collapseProgress > 0.42
  property real reveal: requested ? 1 : 0
  property var displayedNotification: ({})
  readonly property real cardHeight: toastCard.implicitHeight
  // Leave room for the panel shadow without moving the card on screen.
  readonly property int shadowPadding: 55

  screen: bar.screen
  visible: requested || reveal > 0.001
  color: "transparent"
  BackgroundEffect.blurRegion: Shell.Theme.translucent ? toastBlur : null
  onRevealChanged: toastBlur.changed()
  Region {
    id: toastBlur
    item: root.requested && root.reveal > Shell.PanelStyle.blurRevealOpacity ? toastCard.surface : null
    radius: toastCard.surface.radius
  }
  implicitWidth: Notifications.Style.interactiveWidth + shadowPadding * 2
  implicitHeight: cardHeight + Notifications.Style.desktopMargin + shadowPadding
  mask: Region { item: toastCard }

  anchors {
    left: true
    top: true
  }
  margins {
    left: Math.round(Shell.Theme.sidebarOuterMargin + bar.cardWidth
                     + Notifications.Style.desktopMargin) - root.shadowPadding
    top: 0
  }

  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.namespace: "pond-notification-toast-"
      + (outputName || "unknown")
  WlrLayershell.exclusionMode: ExclusionMode.Ignore

  Behavior on reveal { Shell.Motion { duration: Notifications.Style.panelDuration } }

  Component.onCompleted: {
    if (Notifications.State.currentTransient)
      displayedNotification = Notifications.State.currentTransient;
  }

  Connections {
    target: Notifications.State
    function onCurrentTransientChanged() {
      if (Notifications.State.currentTransient)
        root.displayedNotification = Notifications.State.currentTransient;
    }
  }

  Notifications.Card {
    id: toastCard
    x: root.shadowPadding - (1 - root.reveal) * 4
    y: Notifications.Style.desktopMargin
    width: Notifications.Style.interactiveWidth
    height: implicitHeight
    opacity: root.reveal
    notification: root.displayedNotification
    onActivated: Notifications.State.activate(root.displayedNotification)
    onDismissed: Notifications.State.remove(root.displayedNotification)

    Shell.Shadow {
      anchors.fill: toastCard.surface
      cornerRadius: toastCard.surface.radius
      shadows: Shell.PanelStyle.frontShadows
      z: -1
    }
  }
}
