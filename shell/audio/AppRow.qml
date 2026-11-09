import QtQuick
import "." as Audio
import ".."

// One application stream: name, what it is playing, and its own volume.
Item {
  id: root

  property var stream
  property bool interactive: true
  readonly property bool muted: !!(stream && stream.audio && stream.audio.muted)
  readonly property string title: Audio.State.streamTitle(stream)
  signal routeRequested

  implicitWidth: PanelStyle.rowWidth
  implicitHeight: PanelStyle.appRowHeight

  Rectangle {
    anchors.fill: parent
    radius: PanelStyle.rowRadius
    color: rowHover.hovered ? PanelStyle.drawerRowHover
        : Qt.alpha(PanelStyle.drawerRowHover, 0)
    Behavior on color {
      ColorAnimation { duration: PanelStyle.controlDuration; easing.type: Easing.OutCubic }
    }
  }
  HoverHandler { id: rowHover; enabled: root.interactive }

  Row {
    x: 12
    y: 8
    width: 220
    height: 20
    spacing: 6
    clip: true

    Text {
      id: nameLabel
      width: Math.min(implicitWidth, parent.width)
      height: parent.height
      text: Audio.State.appName(root.stream)
      color: Theme.colors.text
      elide: Text.ElideRight
      font.family: Theme.fontFamily
      font.weight: Font.Medium
      font.pixelSize: 13
      verticalAlignment: Text.AlignVCenter
    }
    Text {
      width: Math.max(0, parent.width - nameLabel.width - parent.spacing)
      height: parent.height
      visible: root.title !== "" && width > 16
      text: root.title
      color: Theme.colors.text
      opacity: 0.5
      elide: Text.ElideRight
      font.family: Theme.fontFamily
      font.weight: Font.Medium
      font.pixelSize: 13
      verticalAlignment: Text.AlignVCenter
    }
  }

  // The name line doubles as the way into this stream's device list.
  MouseArea {
    id: routePointer
    width: 252
    height: 30
    enabled: root.interactive
    cursorShape: Qt.PointingHandCursor
    onClicked: root.routeRequested()
    Accessible.role: Accessible.Button
    Accessible.name: "Device for " + nameLabel.text

    Image {
      x: 232
      y: 10
      width: 16
      height: 16
      rotation: -90
      source: Qt.resolvedUrl("../assets/appearance/chevron.svg")
      sourceSize: Qt.size(32, 32)
      opacity: rowHover.hovered ? 1 : 0.45
      Behavior on opacity { HoverAnimation {} }
    }
  }

  IconButton {
    x: 264
    y: 6
    width: 24
    height: 24
    enabled: root.interactive
    iconSource: Qt.resolvedUrl(root.muted ? "../assets/volume-mute.svg" : "../assets/sound.svg")
    iconWidth: 14
    iconHeight: 14
    restingOpacity: root.muted ? 1 : 0.6
    onClicked: Audio.State.toggleStreamMute(root.stream)
    Accessible.role: Accessible.Button
    Accessible.name: root.muted ? "Unmute " + nameLabel.text : "Mute " + nameLabel.text
  }

  Slider {
    id: volumeSlider
    x: 12
    y: 30
    width: 276
    height: 32
    externalValue: Audio.State.streamVolume(root.stream)
    muted: root.muted
    trackColor: PanelStyle.drawerSliderTrack
    interactive: root.interactive
    onMoved: Audio.State.setStreamVolume(root.stream, volumeSlider.value)
  }
}
