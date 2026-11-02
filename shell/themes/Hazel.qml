import QtQuick

Daylight {
  text: "#FFF7E9"

  panelGradient: Gradient {
    GradientStop { position: 0; color: Qt.alpha("#1C1A0C", 0.9) }
    GradientStop { position: 0.75; color: Qt.alpha("#2C271B", 0.9) }
    GradientStop { position: 1; color: Qt.alpha("#403522", 0.9) }
  }
  modalGradient: panelGradient
  panelBorder: Qt.alpha("#FFEFB7", 0.4)
  modalBorder: Qt.alpha("#FFEFB7", 0.25)
  todayFill: "#D1C9FF"
  sliderFill: "#FFF7E9"

  drawerFill: Qt.alpha("#FFF0C5", 0.08)
  drawerHover: Qt.alpha("#FFF0C5", 0.3)
  selectFill: Qt.alpha("#FFF0C5", 0.15)
  drawerSliderBorder: Qt.rgba(0, 0, 0, 0.6)
  menuSurface: "#221B15"
  menuBorder: "#45372B"
  closeFill: "#3D3322"
  closeBorder: Qt.alpha("#FFEFB7", 0.25)
  closeHoverBorder: "#D8B9FD"

  menuCard: Qt.alpha("#615F4F", 0.5)
  menuCardBorder: Qt.rgba(1, 1, 1, 0.4)
  menuCardHoverBorder: Qt.alpha("#FFEFB7", 0.4)
  menuControl: Qt.alpha("#615F4F", 0.5)
  menuCardHover: Qt.alpha("#806B46", 0.9)

  notificationCloseFill: "#FFF0C5"
  dismissGlyph: "#22254D"
  dismissHoverGlyph: "#22254D"
}
