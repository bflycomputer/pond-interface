import QtQuick

Daylight {
  panelGradient: Gradient {
    GradientStop { position: 0; color: Qt.alpha("#102025", 0.8) }
    GradientStop { position: 1; color: Qt.alpha("#081015", 0.8) }
  }
  calendarGradient: Gradient {
    GradientStop { position: 0; color: Qt.alpha("#102025", 0.7) }
    GradientStop { position: 1; color: Qt.alpha("#081015", 0.7) }
  }
  modalGradient: Gradient {
    GradientStop { position: 0; color: Qt.alpha("#111B21", 0.8) }
    GradientStop { position: 1; color: Qt.alpha("#3D565E", 0.8) }
  }
  panelBorder: Qt.alpha("#99DAEE", 0.6)
  modalBorder: Qt.alpha("#99DAEE", 0.25)
  todayFill: "#D1C9FF"
  drawerRowHover: Qt.alpha("#E0F1FB", 0.1)
  closeGlyph: "#E0F1FB"

  drawerFill: Qt.alpha("#E0F1FB", 0.15)
  drawerHover: Qt.alpha("#E0F1FB", 0.3)
  selectFill: drawerFill
  menuSurface: "#0F171A"
  menuBorder: "#29383E"
  closeFill: "#182B31"
  closeBorder: Qt.alpha("#99DAEE", 0.6)
  closeHoverBorder: "#D8B9FD"

  menuCard: Qt.alpha("#56575E", 0.5)
  menuCardBorder: Qt.rgba(1, 1, 1, 0.6)
  menuCardHoverGradient: Gradient {
    GradientStop { position: 0; color: Qt.alpha("#538FA3", 0.5) }
    GradientStop { position: 0.7; color: Qt.alpha("#4A575E", 0.5) }
    GradientStop { position: 1; color: Qt.alpha("#56575E", 0.5) }
  }

  notificationCloseFill: "#B4C7E8"
  dismissGlyph: "#22254D"
  dismissHoverGlyph: "#22254D"
}
