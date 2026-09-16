import QtQuick

Rectangle {
  property color classicColor: Theme.sidebarV3Background
  property bool animateClassicColor: false
  color: Theme.daylight ? (cardHover.hovered ? Theme.sidebarHoverFill : Theme.sidebarClearFill) : classicColor
  border.width: Theme.daylight ? 1 : 0
  border.color: Theme.sidebarCardOutline
  radius: Theme.sidebarCardRadius
  antialiasing: true
  clip: true
  HoverHandler { id: cardHover }
  Behavior on color {
    enabled: Theme.daylight || animateClassicColor
    ColorAnimation { duration: 120; easing.type: Easing.OutCubic }
  }
}
