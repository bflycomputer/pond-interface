import QtQuick
import Quickshell.Widgets
import Pond.Daylight as Daylight
import "../.." as Shell

Item {
  id: root
  property bool adding: false
  property bool dynamic: false
  property bool selected: false
  property string title
  property string subtitle
  property url source
  readonly property bool highlighted: hover.hovered || activeFocus
  signal clicked
  implicitWidth: 276
  implicitHeight: 155
  activeFocusOnTab: true
  Accessible.role: adding ? Accessible.Button : Accessible.RadioButton
  Accessible.name: [title, subtitle].filter(Boolean).join(", ")
  Accessible.checked: selected
  Accessible.onPressAction: clicked()
  Keys.onReturnPressed: clicked()
  Keys.onSpacePressed: clicked()

  ClippingRectangle {
    anchors.fill: parent
    radius: 12
    color: root.adding && root.highlighted ? Shell.PanelStyle.controlHover : Shell.PanelStyle.controlFill
    Image {
      anchors.fill: parent
      source: root.source
      sourceSize: Qt.size(Math.ceil(width * Screen.devicePixelRatio), Math.ceil(height * Screen.devicePixelRatio))
      fillMode: Image.PreserveAspectCrop
      asynchronous: true
      autoTransform: true
    }
    Loader {
      anchors.fill: parent
      active: root.dynamic
      sourceComponent: Daylight.Sky {}
    }
    Image {
      visible: root.adding
      x: 16; y: 16; width: 32; height: 32
      source: Qt.resolvedUrl("../../assets/appearance/add-wallpaper.svg")
    }
    Text {
      visible: root.adding
      x: 24; y: 110
      text: root.title
      font.family: Shell.Theme.titleFontFamily; font.pixelSize: 20
      color: Shell.Theme.colors.text
    }
    Item {
      anchors.fill: parent
      visible: !root.adding && root.highlighted
      Rectangle {
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        height: 55
        gradient: Gradient {
          GradientStop { position: 0; color: "transparent" }
          GradientStop { position: 1; color: Qt.rgba(0, 0, 0, 0.6) }
        }
      }
      Text {
        x: 12; y: 112; width: parent.width - 58
        visible: !!text; text: root.title
        elide: Text.ElideRight
        font.family: Shell.Theme.fontFamily; font.pixelSize: 13; font.weight: Font.Medium
        color: "white"
      }
      Text {
        x: 12; y: 129; width: parent.width - 58
        text: root.subtitle; elide: Text.ElideRight
        font.family: Shell.Theme.fontFamily; font.pixelSize: 13; font.weight: Font.Medium
        color: Qt.rgba(1, 1, 1, 0.49)
      }
    }
    Rectangle {
      visible: root.selected
      x: parent.width - 38; y: parent.height - 38
      width: 26; height: 26; radius: 13
      color: "white"
      Image {
        anchors.centerIn: parent
        width: 16; height: 16; sourceSize: Qt.size(32, 32)
        source: Qt.resolvedUrl("../../assets/check.svg")
      }
    }
  }
  Rectangle {
    anchors { fill: parent; margins: -4 }
    visible: root.selected || root.activeFocus
    radius: 16
    color: "transparent"
    border.width: 1; border.color: Shell.Theme.colors.selection
  }
  HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
  TapHandler { onTapped: root.clicked() }
}
