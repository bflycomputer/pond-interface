pragma ComponentBehavior: Bound

import QtQuick
import ".."

Item {
  id: root
  property bool open: false
  property string currentMode: "wpa-psk"
  property var options: [
    { label: "Open (No password)", mode: "open" },
    { label: "Enhanced Open (OWE)", mode: "owe" },
    { label: "WPA Personal (Legacy)", mode: "wpa" },
    { label: "WPA2 Personal", mode: "wpa2" },
    { label: "WPA2/WPA3 Personal", mode: "wpa-psk" },
    { label: "WPA3 Personal Only", mode: "sae" },
    { label: "WEP Key (Legacy)", mode: "wep" }
  ]
  signal selected(string label, string mode)

  implicitWidth: 276
  implicitHeight: 272
  visible: root.open || root.opacity > 0.001
  enabled: root.open
  opacity: root.open ? 1 : 0
  scale: root.open ? 1 : 0.96
  transformOrigin: Item.Top

  Behavior on opacity {
    NumberAnimation {
      duration: 100
      easing.type: Easing.OutCubic
    }
  }
  Behavior on scale {
    NumberAnimation {
      duration: 100
      easing.type: Easing.OutCubic
    }
  }

  Shadow {
    anchors.fill: parent
    cornerRadius: 16
    shadows: PanelStyle.controlShadows
  }

  Rectangle {
    anchors.fill: parent
    radius: 16
    color: PanelStyle.surface
    border.color: PanelStyle.border
    border.width: 0.5
    clip: true

    ScrollList {
      id: optionList
      x: 8
      y: 8
      width: 259
      height: 256
      model: root.options
      delegate: Rectangle {
        id: optionRow
        required property var modelData
        width: optionList.width
        height: 40
        radius: 12
        color: modelData.mode === root.currentMode || rowHover.hovered
            ? PanelStyle.hover : "transparent"

        Text {
          x: 12
          anchors.verticalCenter: parent.verticalCenter
          text: optionRow.modelData.label
          color: "white"
          font.family: Theme.fontFamily
          font.weight: Font.Medium
          font.pixelSize: 13
        }
        HoverHandler { id: rowHover; cursorShape: Qt.PointingHandCursor }
        TapHandler {
          onTapped: root.selected(optionRow.modelData.label,
                                  optionRow.modelData.mode)
        }
      }
    }

    Rectangle {
      x: 271.5
      y: 15.5 + (optionList.contentHeight <= optionList.height ? 0
          : optionList.contentY / (optionList.contentHeight - optionList.height)
            * (140 - height))
      width: 2
      height: 116
      radius: 17
      color: "white"
      opacity: 0.2
    }
  }
}
