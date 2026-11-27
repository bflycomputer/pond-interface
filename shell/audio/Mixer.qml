pragma ComponentBehavior: Bound

import QtQuick
import "." as Audio
import ".."

Item {
  id: root

  property var stackController
  property bool interactive: true
  property int page: 0

  readonly property real headerDividerY: 91.5
  readonly property var apps: Audio.State.apps
  readonly property int pageCount: Math.max(1, Math.ceil(apps.length / 4))
  onPageCountChanged: page = Math.min(page, pageCount - 1)

  implicitWidth: PanelStyle.width
  implicitHeight: pageCount > 1 ? 417 : 372

  function columnX(column) {
    return Math.round(37 + column * (PanelStyle.width - 74) / 3);
  }

  PanelBackground {
    anchors.fill: parent
    stacked: true

    Text {
      x: 19.5
      y: 16.5
      text: "Master"
      color: Theme.colors.text
      font.family: Theme.titleFontFamily
      font.weight: Font.Normal
      font.pixelSize: 20
    }

    Slider {
      id: masterSlider
      x: 20
      y: 48
      width: PanelStyle.fieldWidth
      height: 32
      externalValue: Audio.State.outputVolume
      muted: Audio.State.outputMuted
      trackColor: PanelStyle.drawerSliderTrack
      interactive: root.interactive && Audio.State.hasOutput
      onMoved: Audio.State.setOutputVolume(masterSlider.value)
    }

    Repeater {
      model: 5
      Rectangle {
        required property int index
        x: index === 0 ? root.columnX(0) - 28 : root.columnX(index - 1) + 20
        y: 226
        width: (index === 4 ? x + 8 : root.columnX(index) - 20) - x
        height: 1
        color: Qt.alpha(Theme.colors.text, 0.1)
        antialiasing: false
      }
    }

    Repeater {
      model: 4
      Text {
        required property int index
        x: (index % 2 ? root.columnX(3) + 24 : root.columnX(0) - 24) - width / 2
        y: (index < 2 ? 141.5 : 310.5) - height / 2
        text: index < 2 ? "+" : "-"
        color: Theme.colors.text
        opacity: 0.4
        font.family: Theme.fontFamily
        font.pixelSize: 15
      }
    }

    Repeater {
      model: 4
      MixerChannel {
        required property int index
        x: root.columnX(index) - width / 2
        y: 112
        app: root.apps[root.page * 4 + index] ?? null
      }
    }

    IconButton {
      x: root.columnX(0) - 12
      y: 368
      visible: root.pageCount > 1
      rotation: 90
      iconSource: Qt.resolvedUrl("../assets/appearance/chevron.svg")
      iconWidth: 16
      iconHeight: 16
      restingOpacity: 1
      onClicked: root.page = (root.page + root.pageCount - 1) % root.pageCount
    }

    IconButton {
      x: root.columnX(3) - 12
      y: 368
      visible: root.pageCount > 1
      rotation: -90
      iconSource: Qt.resolvedUrl("../assets/appearance/chevron.svg")
      iconWidth: 16
      iconHeight: 16
      restingOpacity: 1
      onClicked: root.page = (root.page + 1) % root.pageCount
    }

    Row {
      anchors.horizontalCenter: parent.horizontalCenter
      y: 376
      spacing: 8
      visible: root.pageCount > 1

      Repeater {
        model: root.pageCount
        Rectangle {
          required property int index
          width: 8
          height: 8
          radius: 4
          color: index === root.page ? PanelStyle.sliderFill : "transparent"
          border.width: index === root.page ? 0 : 1
          border.color: Qt.alpha(PanelStyle.sliderFill, 0.6)
        }
      }
    }
  }
}
