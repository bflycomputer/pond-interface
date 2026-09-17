import QtQuick
import "." as Appearance
import "../.." as Shell

Rectangle {
  id: root
  property bool dynamic: false
  property bool selected: false
  signal clicked
  implicitHeight: 64
  z: selected ? 1 : 0
  topLeftRadius: dynamic ? 12 : 0
  topRightRadius: dynamic ? 12 : 0
  bottomLeftRadius: dynamic ? 0 : 12
  bottomRightRadius: dynamic ? 0 : 12
  color: hover.hovered || activeFocus ? "#303030" : selected ? "#333333" : "transparent"
  border.width: 1
  border.color: selected ? "#cba6f7" : hover.hovered || activeFocus ? "#444444" : "#3d3d3d"
  activeFocusOnTab: true
  Accessible.role: Accessible.Button
  Accessible.name: dynamic ? "Dynamic wallpaper" : "Choose a custom wallpaper"
  Accessible.checked: selected
  Keys.onReturnPressed: clicked()
  Keys.onSpacePressed: clicked()
  Accessible.onPressAction: clicked()
  Behavior on color { ColorAnimation { duration: 170; easing.type: Easing.OutCubic } }
  Behavior on border.color { ColorAnimation { duration: 170; easing.type: Easing.OutCubic } }
  Text {
    x: 20; y: 15
    text: root.dynamic ? "Dynamic" : "Custom"
    color: "white"; font.family: Shell.Theme.fontFamily; font.pixelSize: 13
  }
  Text {
    x: 20; y: 32
    text: root.dynamic ? "Changes with the time of day" : "Set your own wallpaper"
    color: "#80ffffff"; font.family: Shell.Theme.fontFamily; font.pixelSize: 13
  }
  Rectangle {
    visible: root.dynamic
    x: parent.width - 90; y: 19; width: 70; height: 26; radius: 4
    gradient: Gradient {
      orientation: Gradient.Horizontal
      GradientStop { position: 0; color: "#484245" }
      GradientStop { position: 0.26; color: "#665042" }
      GradientStop { position: 0.5; color: "#3c4347" }
      GradientStop { position: 0.81; color: "#273440" }
      GradientStop { position: 1; color: "#141d2a" }
    }
  }
  Image {
    visible: !root.dynamic && !Appearance.State.wallpaperPath
    x: parent.width - 44; y: 20; width: 24; height: 24
    source: Qt.resolvedUrl("../../assets/appearance/wallpaper.svg")
  }
  Text {
    visible: !root.dynamic && Appearance.State.wallpaperPath !== ""
    x: parent.width - 190; y: 0; width: 124; height: 64
    text: Appearance.State.wallpaperName
    elide: Text.ElideRight; verticalAlignment: Text.AlignVCenter
    font.family: Shell.Theme.fontFamily; font.pixelSize: 13; color: "#b3b3b3"
  }
  Image {
    visible: !root.dynamic && Appearance.State.wallpaperPath !== ""
    x: parent.width - 56; y: 19; width: 40; height: 26
    source: Appearance.State.wallpaperUrl
    sourceSize: Qt.size(Math.ceil(width * Screen.devicePixelRatio), Math.ceil(height * Screen.devicePixelRatio))
    fillMode: Image.PreserveAspectCrop; asynchronous: true
  }
  HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
  TapHandler { onTapped: root.clicked() }
}
