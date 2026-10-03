import QtQuick
import Quickshell

Rectangle {
  id: root
  default property alias contentData: content.data
  property bool contentClipped: true
  property color classicColor: Theme.sidebarV3Background
  property bool animateClassicColor: false
  readonly property bool cardHovered: cardHover.hovered
  readonly property Region blurRegion: Region {
    item: root
    radius: root.radius
  }
  color: Theme.daylight ? (cardHovered ? Theme.sidebarCardHoverFill : Theme.sidebarCardFill) : classicColor
  border.width: Theme.daylight ? 1 : 0
  border.color: Theme.sidebarCardOutline
  radius: Theme.sidebarCardRadius
  antialiasing: true
  // Clip the contents without cutting off the outline's antialiasing.
  data: Item {
    id: content
    anchors.fill: parent
    clip: root.contentClipped
  }
  HoverHandler { id: cardHover }
  Behavior on color {
    enabled: Theme.daylight || animateClassicColor
    ColorAnimation { duration: 120; easing.type: Easing.OutCubic }
  }
}
