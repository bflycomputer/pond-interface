pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Effects
import Quickshell.Widgets
import "." as Screenshot

Item {
  id: root
  required property string outputName
  property bool collapsed: false
  readonly property bool hasScreenshot: Screenshot.State.imageSource !== ""
      && Screenshot.State.outputName === outputName
  width: collapsed ? 48 : 156
  height: hasScreenshot ? (collapsed ? 48 : 112) : 0
  visible: hasScreenshot

  Rectangle {
    id: shadowShape
    anchors.fill: parent
    radius: 12
    color: "#707070"
    visible: false
    layer.enabled: true
  }
  Repeater {
    model: [
      { blur: 40, offsetY: 4, opacity: 0.10 },
      { blur: 20, offsetY: 3, opacity: 0.12 },
      { blur: 12, offsetY: 3, opacity: 0.15 },
      { blur: 8, offsetY: 2, opacity: 0.20 },
      { blur: 1, offsetY: 1, opacity: 0.25 }
    ]
    MultiEffect {
      required property var modelData
      anchors.fill: root
      source: shadowShape
      shadowEnabled: true
      shadowColor: "black"
      shadowOpacity: modelData.opacity
      shadowBlur: 1
      shadowVerticalOffset: modelData.offsetY
      blurMax: modelData.blur
    }
  }
  ClippingRectangle {
    anchors.fill: parent
    radius: 12
    color: "#707070"
    border { width: 1; color: "#24ffffff" }
    Image {
      id: thumbnail
      objectName: "screenshotThumbnail"
      anchors.fill: parent
      source: Screenshot.State.imageSource
      sourceSize: Qt.size(312, 224)
      fillMode: Image.PreserveAspectCrop
      asynchronous: true
      cache: false
    }
    Rectangle {
      anchors.fill: parent
      color: "black"
      opacity: hover.hovered ? 0.5 : 0.1
      Behavior on opacity { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
    }
  }
  HoverHandler { id: hover }
  TapHandler {
    enabled: root.collapsed
    onTapped: Screenshot.State.copy()
  }

  component ActionButton: Rectangle {
    id: button
    required property string label
    required property url iconSource
    signal activated
    width: 30
    height: 30
    radius: 15
    color: "white"
    opacity: hover.hovered && !root.collapsed ? 1 : 0
    enabled: opacity > 0
    scale: pointer.pressed ? 0.94 : pointer.containsMouse ? 34 / 30 : 1
    Accessible.role: Accessible.Button
    Accessible.name: label
    Accessible.onPressAction: activated()
    Behavior on opacity { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
    Behavior on scale { NumberAnimation { duration: 90; easing.type: Easing.OutCubic } }
    Image {
      anchors.centerIn: parent
      width: 14
      height: 14
      source: button.iconSource
      sourceSize: Qt.size(32, 32)
    }
    MouseArea {
      id: pointer
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: button.activated()
    }
  }
  ActionButton {
    objectName: "dismissScreenshot"
    x: 8
    y: 8
    label: "Dismiss screenshot"
    iconSource: Qt.resolvedUrl("assets/close.svg")
    onActivated: Screenshot.State.dismiss()
  }
  ActionButton {
    objectName: "copyScreenshot"
    x: parent.width - width - 8
    y: 8
    label: "Copy screenshot"
    iconSource: Qt.resolvedUrl("assets/copy.svg")
    onActivated: Screenshot.State.copy()
  }
  Rectangle {
    anchors.horizontalCenter: parent.horizontalCenter
    y: -13
    width: 60
    height: 25
    radius: 13
    color: "#CBA6F7"
    visible: Screenshot.State.copied && !root.collapsed
    Text {
      anchors.centerIn: parent
      text: "Copy’d"
      color: "#3D2C52"
      font { family: "Onest"; pixelSize: 13; weight: Font.Medium }
    }
  }
}
