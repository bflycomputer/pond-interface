import QtQuick

Unthemed {
  translucent: true

  panelSurface: Qt.alpha("#202020", 0.8)
  modalSurface: Qt.alpha("#292929", panelSurface.a)
  panelBorder: Qt.alpha("#2F2F2F", 0.8)
  todayFill: accent

  drawerFill: Qt.rgba(1, 1, 1, 0.08)
  drawerHover: Qt.rgba(1, 1, 1, 0.12)
  drawerRowHover: Qt.rgba(1, 1, 1, 0.10)
  drawerSliderTrack: Qt.alpha("#F9EFFF", 0.1)
  drawerToggleAlpha: 0.12
  fieldFocus: drawerFill
  selectFill: Qt.rgba(1, 1, 1, 0.12)
  checkFill: Qt.rgba(0, 0, 0, 0.2)
  checkHover: Qt.rgba(0, 0, 0, 0.3)
  checkMark: "#D9D9D9"
  menuSurface: "#191A1B"
  menuBorder: "#3A3A3A"
  menuRowHover: drawerFill
  closeFill: "#323232"
  closeBorder: Qt.alpha("#575757", 0.5)
  closeHover: accent
  closeHoverBorder: Qt.alpha("#684098", 0.5)

  overlayOpacity: 0.8
  menuCard: Qt.alpha("#494949", 0.5)
  menuControl: Qt.alpha("#56575E", 0.5)
  menuCardHover: Qt.alpha("#707070", 0.5)
  trayHover: menuControl
  sessionControl: Qt.rgba(1, 1, 1, 0.15)

  notificationHover: drawerFill
  notificationCloseFill: "#D1C9FF"
  notificationCloseHover: accent

  sidebarCardFill: Qt.rgba(0, 0, 0, 0.12)
  sidebarCardOutline: Qt.alpha("#F9EFFF", 0.1)
  sidebarInnerOutline: Qt.rgba(1, 1, 1, 0.20)
  sidebarSliderTrack: sidebarInnerOutline
  sidebarButtonSelected: Qt.alpha("#F9EFFF", 0.1)
  sidebarButtonHover: sidebarButtonSelected
  sidebarButtonRest: Qt.alpha(sidebarButtonSelected, 0)
  feedbackDotOff: sidebarInnerOutline
  clockChipBorder: sidebarInnerOutline
  sidebarDivider: sidebarCardOutline
  installHover: sidebarHoverFill
  inlineFill: Qt.tint(Qt.alpha("#F9EFFF", 0.1), sidebarClearFill)
  inlineHoverFill: Qt.tint(Qt.alpha("#F9EFFF", 0.1), sidebarHoverFill)

  workspaceLauncherActive: sidebarHoverFill
  workspaceActiveIndicatorColor: sidebarHoverFill
  workspaceCollapsedActive: Qt.rgba(1, 1, 1, 0.08)
  workspaceActiveRing: workspaceIconOutline
  workspaceIconOutline: sidebarCardOutline
  workspaceControlHover: Qt.rgba(1, 1, 1, 0.10)
  workspacePlaceholderColor: Qt.rgba(1, 1, 1, 0.30)
  workspaceDropFill: Qt.rgba(1, 1, 1, 0.20)
  workspaceDropStroke: workspaceDropFill
  workspaceNumberText: "white"
  workspaceNumberBackground: "#5B5B5B"
  workspaceNumberDragBackground: "#787878"
  workspaceDragBackground: "#53525D"
}
