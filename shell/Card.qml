import QtQuick

Rectangle {
  property color classicColor: Theme.sidebarV3Background
  property bool animateClassicColor: false
  color: classicColor
  radius: Theme.sidebarCardRadius
  antialiasing: true
  clip: true
  Behavior on color {
    enabled: animateClassicColor
    ColorAnimation { duration: 120; easing.type: Easing.OutCubic }
  }
}
