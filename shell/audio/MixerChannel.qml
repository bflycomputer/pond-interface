pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Templates as T
import Quickshell
import Quickshell.Services.Pipewire
import "." as Audio
import ".."

Item {
  id: root

  property var app: null

  readonly property int offset: Math.round(slider.value * 100) - 100
  readonly property real handleCenterY: slider.y + slider.topPadding
      + slider.visualPosition * slider.availableHeight
  readonly property bool live: {
    for (let i = 0; i < monitors.count; i++) {
      if (monitors.objectAt(i)?.live)
        return true;
    }
    return false;
  }
  readonly property var links: Pipewire.linkGroups.values.filter(group =>
      root.app && root.app.nodes.includes(group.source))

  implicitWidth: 26
  implicitHeight: 236

  PwObjectTracker { objects: root.links }

  Instantiator {
    id: monitors
    model: ScriptModel { values: root.app ? root.app.nodes : [] }
    delegate: PwNodePeakMonitor {
      required property var modelData
      readonly property bool measurable: !modelData.audio.channels.includes(PwAudioChannel.Unknown)
      readonly property bool live: measurable ? peak > 0.1 : root.links.some(group =>
          group.source === modelData && group.state === PwLinkState.Active)
      node: modelData
      enabled: measurable
    }
  }

  Rectangle {
    x: 7
    width: 12
    height: 12
    radius: 6
    color: root.live ? "#CBE25B" : "transparent"
    border.width: root.live ? 0 : 1
    border.color: Qt.alpha(Theme.colors.text, 0.2)
  }

  Rectangle {
    x: 7
    y: 24
    width: 12
    height: 180
    radius: 6
    color: "transparent"
    border.width: 1
    border.color: Qt.alpha(Theme.colors.text, 0.2)
  }

  Rectangle {
    x: 9
    y: Math.min(114, root.handleCenterY)
    width: 8
    height: Math.abs(root.handleCenterY - 114)
    visible: !!root.app
    color: Qt.alpha(PanelStyle.sliderFill, 0.5)
  }

  T.Slider {
    id: slider
    y: 24
    width: 26
    height: 180
    orientation: Qt.Vertical
    from: 0
    to: 2
    topPadding: 13
    bottomPadding: 13
    visible: !!root.app
    focusPolicy: Qt.NoFocus
    handle: Item { width: 0; height: 0 }
    Binding on value {
      value: root.app ? root.app.nodes[0].audio.volume : 1
      when: !slider.pressed
      restoreMode: Binding.RestoreNone
    }
    onMoved: Audio.State.setAppVolume(root.app, slider.value)

    HoverHandler { cursorShape: Qt.PointingHandCursor }
  }

  Rectangle {
    id: handle
    y: root.handleCenterY - 13
    width: 26
    height: 26
    radius: 13
    visible: !!root.app
    color: PanelStyle.sliderFill
    border.width: 1
    border.color: PanelStyle.border

    Text {
      anchors.centerIn: parent
      anchors.verticalCenterOffset: 1
      visible: root.offset !== 0
      text: Math.abs(root.offset)
      color: PanelStyle.surface
      font.family: Theme.fontFamily
      font.weight: Font.Medium
      font.pixelSize: 13
    }
  }

  Text {
    anchors.right: handle.left
    anchors.rightMargin: 4
    anchors.verticalCenter: handle.verticalCenter
    visible: handle.visible && root.offset !== 0
    text: root.offset > 0 ? "+" : "-"
    color: Theme.colors.text
    font.family: Theme.fontFamily
    font.weight: Font.Medium
    font.pixelSize: 15
  }

  Image {
    x: 3
    y: 216
    width: 20
    height: 20
    visible: !!root.app
    source: root.app ? root.app.icon : ""
    sourceSize: Qt.size(40, 40)
  }

  Rectangle {
    x: 3
    y: 216
    width: 20
    height: 20
    radius: 10
    visible: !root.app
    color: "transparent"
    border.width: 1
    border.color: Qt.alpha(Theme.colors.text, 0.2)
  }
}
