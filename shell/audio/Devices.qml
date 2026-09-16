pragma ComponentBehavior: Bound

import QtQuick
import "." as Audio
import ".."

Item {
  id: root

  property bool interactive: true
  property string selectedTab: "output"

  readonly property var devices: selectedTab === "output"
      ? Audio.State.outputDevices : Audio.State.inputDevices
  readonly property int deviceCount: devices.length
  readonly property int visibleDeviceRows: Math.max(1,
      Math.min(4, deviceCount))
  readonly property real selectedVolume: selectedTab === "output"
      ? Audio.State.outputVolume : Audio.State.inputVolume
  readonly property bool selectedAudioAvailable: selectedTab === "output"
      ? Audio.State.hasOutput : Audio.State.hasInput

  implicitWidth: PanelStyle.width
  implicitHeight: 114 + visibleDeviceRows * PanelStyle.audioRowHeight

  PanelBackground {
    anchors.fill: parent

    Repeater {
      model: [
        {tab: "output", label: "Output", x: 16, width: 75, labelX: 3.5, labelWidth: 65},
        {tab: "input", label: "Input", x: 91, width: 65, labelX: 5.5, labelWidth: 49}
      ]
      delegate: MouseArea {
        id: tabButton
        required property var modelData
        x: modelData.x
        y: 12
        width: modelData.width
        height: 40
        enabled: root.interactive
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.selectedTab = modelData.tab

        Text {
          x: tabButton.modelData.labelX
          y: 4
          width: tabButton.modelData.labelWidth
          height: 32
          text: tabButton.modelData.label
          color: "white"
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

    Slider {
      id: volumeSlider
      x: 20
      y: 55
      width: PanelStyle.fieldWidth
      height: 32
      externalValue: root.selectedVolume
      persistentHandle: true
      interactive: root.interactive && root.selectedAudioAvailable
      onMoved: {
        if (root.selectedTab === "output")
          Audio.State.setOutputVolume(volumeSlider.value);
        else
          Audio.State.setInputVolume(volumeSlider.value);
      }
    }

    Rectangle {
      x: 20
      y: 97
      width: 276
      height: 1
      color: PanelStyle.border
      antialiasing: false
    }

    ScrollList {
      id: deviceList
      x: 8
      y: 98
      width: PanelStyle.rowWidth
      height: parent.height - y
      interactive: root.deviceCount > 4
      model: root.devices
      topMargin: 8
      bottomMargin: 8

      delegate: DeviceRow {
        required property var modelData
        width: deviceList.width
        device: modelData
        interactive: root.interactive
        selected: root.selectedTab === "output"
            ? !!Audio.State.sink
                && Number(Audio.State.sink.id) === Number(modelData.id)
            : !!Audio.State.source
                && Number(Audio.State.source.id) === Number(modelData.id)
        onClicked: {
          if (root.selectedTab === "output")
            Audio.State.setOutputDevice(modelData);
          else
            Audio.State.setInputDevice(modelData);
        }
      }

    }

    Text {
      x: 20
      y: 114
      width: 276
      height: 24
      visible: root.deviceCount === 0
      text: root.selectedTab === "output"
          ? "No output devices" : "No input devices"
      color: "white"
      opacity: 0.5
      font.family: Theme.fontFamily
      font.weight: Font.Medium
      font.pixelSize: 13
      verticalAlignment: Text.AlignVCenter
    }

    ScrollShade { view: deviceList; x: 0; y: 98; z: 3; width: parent.width; easingType: Easing.OutCubic }
  }
}
