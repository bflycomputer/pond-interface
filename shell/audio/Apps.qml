pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import "." as Audio
import ".."

// Per-application mixer. Mirrors the Output/Input card: two tabs and a list
// of streams, each of which can be sent to a different device.
Item {
  id: root

  property bool interactive: true
  property string selectedTab: "playback"
  // Non-null while the list shows the devices one stream can be moved to.
  property var routingStream: null
  readonly property bool routing: routingStream !== null

  readonly property var streams: selectedTab === "playback"
      ? Audio.State.playbackStreams : Audio.State.recordingStreams
  readonly property int streamCount: streams.length
  readonly property var devices: selectedTab === "playback"
      ? Audio.State.outputDevices : Audio.State.inputDevices
  readonly property var routingDevice: Audio.State.streamDevice(routingStream)
  readonly property int visibleRows: Math.max(1, Math.min(4,
      routing ? devices.length : streamCount))
  readonly property real listHeight: 16 + (routing
      ? visibleRows * PanelStyle.audioRowHeight
      : streamCount === 0 ? PanelStyle.audioRowHeight
                          : visibleRows * PanelStyle.appRowHeight)

  onSelectedTabChanged: routingStream = null
  // The app can close while its devices are on screen.
  onStreamsChanged: if (routing && streams.indexOf(routingStream) < 0) routingStream = null

  implicitWidth: PanelStyle.width
  implicitHeight: 57 + listHeight

  PanelBackground {
    anchors.fill: parent

    Repeater {
      model: [
        {tab: "playback", label: "Playback", x: 16, width: 95, labelX: 3.5, labelWidth: 85},
        {tab: "recording", label: "Recording", x: 111, width: 105, labelX: 5.5, labelWidth: 95}
      ]
      delegate: MouseArea {
        id: tabButton
        required property var modelData
        visible: !root.routing
        x: modelData.x
        y: 12
        width: modelData.width
        height: 40
        enabled: root.interactive && !root.routing
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.selectedTab = modelData.tab

        Text {
          x: tabButton.modelData.labelX
          y: 4
          width: tabButton.modelData.labelWidth
          height: 32
          text: tabButton.modelData.label
          color: Theme.colors.text
          opacity: root.selectedTab === tabButton.modelData.tab ? 1
              : tabButton.containsMouse ? 0.6 : 0.3
          font.family: Theme.titleFontFamily
          font.weight: Font.Normal
          font.pixelSize: 20
          verticalAlignment: Text.AlignVCenter
          Behavior on opacity { HoverAnimation {} }
        }
      }
    }

    // Routing takes over the header: back out of it, or pick a device below.
    MouseArea {
      id: backButton
      visible: root.routing
      x: 16
      y: 12
      width: 284
      height: 40
      enabled: root.interactive && root.routing
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: root.routingStream = null
      Accessible.role: Accessible.Button
      Accessible.name: "Back to apps"

      Image {
        x: 2
        anchors.verticalCenter: parent.verticalCenter
        width: 16
        height: 16
        rotation: 90
        source: Qt.resolvedUrl("../assets/appearance/chevron.svg")
        sourceSize: Qt.size(32, 32)
        opacity: backButton.containsMouse ? 1 : 0.6
      }
      Text {
        x: 26
        y: 4
        width: 258
        height: 32
        text: Audio.State.appName(root.routingStream)
        color: Theme.colors.text
        elide: Text.ElideRight
        opacity: backButton.containsMouse ? 1 : 0.8
        font.family: Theme.titleFontFamily
        font.weight: Font.Normal
        font.pixelSize: 20
        verticalAlignment: Text.AlignVCenter
      }
    }

    Rectangle {
      x: 20
      y: 56
      width: 276
      height: 1
      color: PanelStyle.outline
      antialiasing: false
    }

    ListView {
      id: streamList
      visible: !root.routing
      clip: true
      boundsBehavior: Flickable.StopAtBounds
      ScrollWheel { view: streamList }
      x: 8
      y: 57
      width: PanelStyle.rowWidth
      height: root.listHeight
      interactive: root.streamCount > 4
      model: ScriptModel { values: root.streams }
      topMargin: 8
      bottomMargin: 8

      delegate: AppRow {
        required property var modelData
        width: streamList.width
        stream: modelData
        interactive: root.interactive
        onRouteRequested: root.routingStream = modelData
      }
    }

    ListView {
      id: deviceList
      visible: root.routing
      clip: true
      boundsBehavior: Flickable.StopAtBounds
      ScrollWheel { view: deviceList }
      x: 8
      y: 57
      width: PanelStyle.rowWidth
      height: root.listHeight
      interactive: root.devices.length > 4
      model: ScriptModel { values: root.routing ? root.devices : [] }
      topMargin: 8
      bottomMargin: 8

      delegate: DeviceRow {
        required property var modelData
        width: deviceList.width
        device: modelData
        interactive: root.interactive
        selected: !!root.routingDevice
            && Number(root.routingDevice.id) === Number(modelData.id)
        onClicked: {
          Audio.State.moveStream(root.routingStream, modelData);
          root.routingStream = null;
        }
      }
    }

    Text {
      x: 20
      y: 65
      width: 276
      height: PanelStyle.audioRowHeight
      visible: root.routing ? root.devices.length === 0 : root.streamCount === 0
      text: root.routing
          ? (root.selectedTab === "playback" ? "No output devices" : "No input devices")
          : root.selectedTab === "playback"
              ? "No apps are playing audio" : "No apps are recording"
      color: Theme.colors.text
      opacity: 0.5
      font.family: Theme.fontFamily
      font.weight: Font.Medium
      font.pixelSize: 13
      verticalAlignment: Text.AlignVCenter
    }

    ScrollShade { view: streamList; x: 0; y: 57; z: 3; width: parent.width; easingType: Easing.OutCubic }
    ScrollShade { view: deviceList; x: 0; y: 57; z: 3; width: parent.width; easingType: Easing.OutCubic }
  }
}
