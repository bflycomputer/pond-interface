import QtQuick

Daylight {
  panelGradient: Gradient {
    GradientStop { position: 0; color: Qt.alpha("#1B1B33", 0.9) }
    GradientStop { position: 0.77; color: Qt.alpha("#5B5382", 0.9) }
    GradientStop { position: 0.93; color: Qt.alpha("#846D95", 0.9) }
    GradientStop { position: 0.97; color: Qt.alpha("#987A9F", 0.9) }
    GradientStop { position: 1; color: Qt.alpha("#AD87A8", 0.9) }
  }
  modalGradient: Gradient {
    GradientStop { position: 0; color: Qt.alpha("#1D1C37", 0.8) }
    GradientStop { position: 0.75; color: Qt.alpha("#4B4373", 0.8) }
    GradientStop { position: 1; color: Qt.alpha("#A3799E", 0.8) }
  }
  panelBorder: "#D8B9FD"
  todayFill: "#D1C9FF"

  drawerFill: Qt.alpha("#F0D7FF", 0.15)
  drawerHover: Qt.alpha("#F0D7FF", 0.3)
  selectFill: drawerFill
  menuSurface: "#271D31"
  menuBorder: "#45372B"
  closeFill: "#574F78"
  closeBorder: "#D8B9FD"
  closeHoverBorder: "#D8B9FD"

  menuCard: Qt.alpha("#56575E", 0.5)
  menuCardHoverGradient: Gradient {
    GradientStop { position: 0; color: Qt.alpha("#515F70", 0.8) }
    GradientStop { position: 0.76; color: Qt.alpha("#7D7BA8", 0.8) }
    GradientStop { position: 1; color: Qt.alpha("#A28EA4", 0.8) }
  }

  dismissHoverGlyph: "#22254D"
}
