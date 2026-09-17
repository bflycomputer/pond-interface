import QtQuick
import Quickshell.Widgets
import "." as Media
import ".." as Shell

Shell.Card {
  id: root

  property real collapseProgress: 0
  readonly property real layoutProgress:
      Shell.Theme.collapseWidth(collapseProgress)
  readonly property bool hasPlayer: Media.State.hasPlayer
  readonly property bool revealed: hasPlayer && (hover.hovered || pointer.pressed)
  property real expandedTargetHeight: hasPlayer ? (revealed ? 92 : 64) : 0
  property real collapsedTargetHeight: hasPlayer
      ? (pointer.pressed ? 126 : (revealed ? 116 : 48)) : 0
  readonly property url playPauseIconSource: Qt.resolvedUrl(
      Media.State.isPlaying ? "../assets/media/pause.svg"
                           : "../assets/media/play.svg")
  readonly property url playPauseHoverIconSource: Qt.resolvedUrl(
      Media.State.isPlaying ? "../assets/media/pause.svg"
                           : "../assets/media/play-hover.svg")
  readonly property real playPauseRestingOpacity: Media.State.isPlaying ? 0.5 : 1.0
  readonly property string displayTitle: Media.State.title !== ""
      ? Media.State.title : (Media.State.identity !== ""
                            ? Media.State.identity : "Unknown track")

  width: Shell.Theme.lerp(Shell.Theme.sidebarCardExpandedWidth,
      Shell.Theme.sidebarCardCollapsedWidth, layoutProgress)
  height: Shell.Theme.lerp(expandedTargetHeight, collapsedTargetHeight,
      Shell.Theme.collapseHeight(collapseProgress))
  visible: height > 0
  classicColor: revealed ? Shell.Theme.mediaHoverBackground : Shell.Theme.sidebarV3Background
  animateClassicColor: true

  Behavior on expandedTargetHeight {
    enabled: root.collapseProgress === 0
    Shell.Motion { duration: Shell.Theme.mediaRevealDuration }
  }
  Behavior on collapsedTargetHeight {
    enabled: root.collapseProgress === 1
    Shell.Motion { duration: Shell.Theme.mediaRevealDuration }
  }

  HoverHandler {
    id: hover
    cursorShape: Qt.PointingHandCursor
  }

  MouseArea {
    id: pointer
    anchors.fill: parent
    acceptedButtons: Qt.LeftButton
    cursorShape: Qt.PointingHandCursor
  }

  ClippingRectangle {
    anchors.fill: parent
    radius: root.radius
    color: "transparent"
    visible: root.hasPlayer

    AlbumCover {
      id: artwork
      x: Shell.Theme.lerp(12, 8, root.layoutProgress)
      y: Shell.Theme.lerp(12, pointer.pressed ? 12 : 8, Shell.Theme.collapseHeight(root.collapseProgress))
      artSize: Shell.Theme.lerp(40, 32, root.layoutProgress)
      Behavior on y {
        enabled: root.collapseProgress === 1
        NumberAnimation { duration: Shell.Theme.mediaRevealDuration; easing.type: Easing.OutCubic }
      }
    }

    // The metadata stays in place as the shrinking card masks it from the right.
    Item {
      x: artwork.x + artwork.width + 8
      y: artwork.y
      width: Math.max(0, root.width - x - Shell.Theme.lerp(12, 8, root.layoutProgress))
      height: 38
      clip: true
      Column {
        width: 84
        Media.MarqueeText {
          width: parent.width
          height: 19
          text: root.displayTitle
          textColor: Shell.Theme.sidebarV3Foreground
          fadeColor: root.color
          fontWeight: Font.Medium
          playing: Media.State.isPlaying
        }
        Media.MarqueeText {
          width: parent.width
          height: 19
          text: Media.State.subtitle
          textColor: Qt.rgba(0.973, 0.976, 0.976, 0.5)
          fadeColor: root.color
          fontWeight: Font.Normal
          playing: Media.State.isPlaying
        }
      }
    }

    // Growing/shrinking this mask reveals the same controls in either layout.
    Item {
      x: Shell.Theme.lerp(40, 14, root.layoutProgress)
      y: Shell.Theme.lerp(56, pointer.pressed ? 55 : 48, Shell.Theme.collapseHeight(root.collapseProgress))
      width: Shell.Theme.lerp(76, 20, root.layoutProgress)
      height: Math.max(0, root.height - Shell.Theme.lerp(64, 48,
          Shell.Theme.collapseHeight(root.collapseProgress)))
      clip: true
      enabled: root.revealed
      Controls { anchors.fill: parent; layoutProgress: root.layoutProgress; verticalProgress: Shell.Theme.collapseHeight(root.collapseProgress) }
    }
  }
  component Controls: Item {
    id: controls
    property real layoutProgress: 0
    property real verticalProgress: 0
    ControlButton {
      x: Shell.Theme.lerp(4, 0, controls.layoutProgress)
      y: Shell.Theme.lerp(4, 0, controls.verticalProgress)
      iconSource: Qt.resolvedUrl("../assets/media/previous.svg")
      hoverIconSource: Qt.resolvedUrl(
          "../assets/media/previous-hover.svg")
      available: Media.State.canPrevious
      onClicked: Media.State.previous()
    }

    ControlButton {
      x: Shell.Theme.lerp(28, 0, controls.layoutProgress)
      y: Shell.Theme.lerp(4, 20, controls.verticalProgress)
      iconSource: root.playPauseIconSource
      hoverIconSource: root.playPauseHoverIconSource
      restingOpacity: root.playPauseRestingOpacity
      available: Media.State.canPlayPause
      onClicked: Media.State.playPause()
    }

    ControlButton {
      x: Shell.Theme.lerp(52, 0, controls.layoutProgress)
      y: Shell.Theme.lerp(4, 40, controls.verticalProgress)
      iconSource: Qt.resolvedUrl("../assets/media/next.svg")
      hoverIconSource: Qt.resolvedUrl(
          "../assets/media/next-hover.svg")
      available: Media.State.canNext
      onClicked: Media.State.next()
    }
  }

  component AlbumCover: ClippingRectangle {
    property real artSize: 40
    width: artSize
    height: artSize
    radius: 4
    color: Shell.Theme.sidebarV3Border

    Image {
      anchors.fill: parent
      source: Media.State.artUrl
      sourceSize: Qt.size(80, 80)
      fillMode: Image.PreserveAspectCrop
      asynchronous: true
      smooth: true
    }
  }

  component ControlButton: Item {
    id: root

    property url iconSource
    property url hoverIconSource: iconSource
    property real restingOpacity: 1.0
    property bool available: true
    signal clicked

    readonly property bool hovered: pointer.containsMouse

    implicitWidth: Shell.Theme.mediaControlSize
    implicitHeight: Shell.Theme.mediaControlSize

    Image {
      anchors.fill: parent
      source: root.hovered ? root.hoverIconSource : root.iconSource
      sourceSize: Qt.size(Shell.Theme.mediaControlSize * 2,
                          Shell.Theme.mediaControlSize * 2)
      fillMode: Image.PreserveAspectFit
      smooth: true
      antialiasing: true
      opacity: root.available
          ? (root.hovered ? 1.0 : root.restingOpacity) : 0.35

      Behavior on opacity { Shell.HoverAnimation {} }
    }

    MouseArea {
      id: pointer
      anchors.fill: parent
      anchors.margins: -4
      enabled: root.available
      hoverEnabled: true
      acceptedButtons: Qt.LeftButton
      cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
      onClicked: root.clicked()
    }
  }
}
