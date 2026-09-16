import QtQuick
import Quickshell.Widgets
import "." as Media
import ".." as Shell

Item {
  id: root

  property real collapseProgress: 0
  readonly property bool hasPlayer: Media.State.hasPlayer
  readonly property url playPauseIconSource: Qt.resolvedUrl(
      Media.State.isPlaying ? "../assets/media/pause.svg"
                           : "../assets/media/play.svg")
  readonly property url playPauseHoverIconSource: Qt.resolvedUrl(
      Media.State.isPlaying ? "../assets/media/pause.svg"
                           : "../assets/media/play-hover.svg")
  readonly property real playPauseRestingOpacity:
      Media.State.isPlaying ? 0.5 : 1.0
  readonly property real expandedOpacity:
      1 - Shell.Theme.ramp(collapseProgress, 0.22, 0.58)
  readonly property real collapsedOpacity:
      Shell.Theme.ramp(collapseProgress, 0.66, 0.92)
  readonly property bool expandedRevealed: hasPlayer
      && (expandedHover.hovered || expandedPointer.pressed)
  readonly property bool collapsedRevealed: hasPlayer
      && (collapsedHover.hovered || collapsedPointer.pressed)
  readonly property real expandedTargetHeight: hasPlayer
      ? (expandedRevealed ? 92 : 64)
      : 0
  readonly property real collapsedTargetHeight: !hasPlayer
      ? 0
      : (collapsedPointer.pressed
         ? 126
         : (collapsedRevealed ? 116 : 48))
  readonly property string displayTitle: Media.State.title !== ""
      ? Media.State.title : (Media.State.identity !== ""
                            ? Media.State.identity : "Unknown track")

  width: Shell.Theme.lerp(Shell.Theme.sidebarCardExpandedWidth,
                    Shell.Theme.sidebarCardCollapsedWidth,
                    Shell.Theme.ramp(collapseProgress, 0.12, 0.88))
  height: Shell.Theme.lerp(expandedTargetHeight, collapsedTargetHeight,
                     Shell.Theme.ramp(collapseProgress, 0.24, 0.84))
  clip: true
  visible: height > 0

  Behavior on height {
    enabled: root.collapseProgress === 0 || root.collapseProgress === 1
    Shell.Motion { duration: Shell.Theme.mediaRevealDuration }
  }

  Shell.Card {
    id: expandedSurface
    width: Shell.Theme.sidebarCardExpandedWidth
    height: root.expandedTargetHeight
    radius: Shell.Theme.sidebarCardRadius
    classicColor: (expandedHover.hovered || expandedPointer.pressed
           ? Shell.Theme.mediaHoverBackground : Shell.Theme.sidebarV3Background)
    opacity: root.expandedOpacity
    visible: opacity > 0.001
    enabled: root.collapseProgress < 0.58
    clip: true
    antialiasing: true

    animateClassicColor: true

    HoverHandler {
      id: expandedHover
      enabled: expandedSurface.enabled
      cursorShape: Qt.PointingHandCursor
    }

    MouseArea {
      id: expandedPointer
      anchors.fill: parent
      z: 1
      enabled: expandedSurface.enabled
      acceptedButtons: Qt.LeftButton
      cursorShape: Qt.PointingHandCursor
    }

    Item {
      anchors.fill: parent
      visible: root.hasPlayer
      z: 2

      AlbumCover {
        x: 12
        y: 12
        artSize: 40
      }

      Column {
        x: 60
        y: 12
        width: 84
        spacing: 0

        Media.MarqueeText {
          width: parent.width
          height: 19
          text: root.displayTitle
          textColor: Shell.Theme.sidebarV3Foreground
          fadeColor: expandedSurface.color
          fontWeight: Font.Medium
          playing: Media.State.isPlaying
        }

        Media.MarqueeText {
          width: parent.width
          height: 19
          text: Media.State.subtitle
          textColor: Qt.rgba(0.973, 0.976, 0.976, 0.5)
          fadeColor: expandedSurface.color
          fontWeight: Font.Normal
          playing: Media.State.isPlaying
        }
      }

      Item {
        x: 40
        y: 56
        width: 76
        height: 28
        opacity: root.expandedRevealed ? 1.0 : 0.0
        visible: opacity > 0.001
        enabled: root.expandedRevealed

        Behavior on opacity { Shell.HoverAnimation {} }

        Controls { anchors.fill: parent }
      }
    }
  }

  Shell.Card {
    id: collapsedSurface
    width: Shell.Theme.sidebarCardCollapsedWidth
    height: root.collapsedTargetHeight
    radius: Shell.Theme.sidebarCardRadius
    classicColor: (collapsedHover.hovered || collapsedPointer.pressed
           ? Shell.Theme.mediaHoverBackground : Shell.Theme.sidebarV3Background)
    opacity: root.collapsedOpacity
    visible: opacity > 0.001
    enabled: root.collapseProgress >= 0.58
    clip: true
    antialiasing: true

    animateClassicColor: true

    HoverHandler {
      id: collapsedHover
      enabled: collapsedSurface.enabled
      cursorShape: Qt.PointingHandCursor
    }

    MouseArea {
      id: collapsedPointer
      anchors.fill: parent
      z: 1
      enabled: collapsedSurface.enabled
      acceptedButtons: Qt.LeftButton
      cursorShape: Qt.PointingHandCursor
    }

    AlbumCover {
      x: 8
      y: collapsedPointer.pressed ? 12 : 8
      artSize: 32
      visible: root.hasPlayer
      z: 2

      Behavior on y {
        NumberAnimation {
          duration: Shell.Theme.mediaRevealDuration
          easing.type: Easing.OutCubic
        }
      }
    }

    Item {
      anchors.fill: parent
      visible: root.hasPlayer && root.collapsedRevealed
      enabled: visible
      opacity: visible ? 1.0 : 0.0
      z: 3

      Controls {
        x: 14
        y: collapsedPointer.pressed ? 55 : 48
        vertical: true
      }
    }
  }
  component Controls: Item {
    id: controls
    property bool vertical: false
    ControlButton {
      x: controls.vertical ? 0 : 4
      y: controls.vertical ? 0 : 4
      iconSource: Qt.resolvedUrl("../assets/media/previous.svg")
      hoverIconSource: Qt.resolvedUrl(
          "../assets/media/previous-hover.svg")
      available: Media.State.canPrevious
      onClicked: Media.State.previous()
    }

    ControlButton {
      x: controls.vertical ? 0 : 28
      y: controls.vertical ? 20 : 4
      iconSource: root.playPauseIconSource
      hoverIconSource: root.playPauseHoverIconSource
      restingOpacity: root.playPauseRestingOpacity
      available: Media.State.canPlayPause
      onClicked: Media.State.playPause()
    }

    ControlButton {
      x: controls.vertical ? 0 : 52
      y: controls.vertical ? 40 : 4
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
      sourceSize: Qt.size(Math.ceil(width * 2), Math.ceil(height * 2))
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
