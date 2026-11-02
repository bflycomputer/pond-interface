import QtQuick

// Every colour a theme can set, with Unthemed's values.
QtObject {
  // Surfaces are see-through and blur what's behind them.
  property bool translucent: false

  property color text: "white"
  property color accent: "#CBA6F7"
  property color selection: accent
  property color errorText: accent

  property color surface: "#1D1D1D"
  property color backSurface: "#131313"
  property color border: "#3D3D3D"
  property color panelSurface: surface
  property color panelBorder: Qt.alpha(border, 0.8)
  property Gradient panelGradient: null
  property Gradient calendarGradient: panelGradient
  property color hover: "#262626"
  property color pressed: "#303030"
  property color outline: Qt.rgba(1, 1, 1, 0.10)

  property color controlFill: Qt.rgba(1, 1, 1, 0.05)
  property color controlHover: Qt.rgba(1, 1, 1, 0.10)
  property color rowHover: Qt.rgba(1, 1, 1, 0.06)
  property color settingsRow: controlFill
  property color accordionRow: controlFill
  property color monitorFill: controlFill
  property color weekFill: Qt.rgba(1, 1, 1, 0.06)
  property color sliderTrack: Qt.rgba(1, 1, 1, 0.07)
  property color sliderFill: "#E7E7E7"
  property color sliderBubble: "#D1D1D1"
  property color todayFill: "#D1C9FF"

  property color drawerFill: controlFill
  property color drawerHover: controlHover
  property color drawerRowHover: rowHover
  property color drawerSliderTrack: sliderTrack
  property color drawerSliderBorder: border
  property real drawerToggleAlpha: 0.06
  property color fieldFocus: controlHover
  property color selectFill: controlHover
  property color checkFill: hover
  property color checkHover: pressed
  property color checkMark: accent
  property color menuSurface: surface
  property color menuBorder: border
  property color menuRowHover: rowHover
  property color closeFill: hover
  property color closeHover: pressed
  property color closeBorder: Qt.alpha(border, 0.5)
  property color closeHoverBorder: closeBorder
  property color closeHoverGlyph: "#38224D"

  property real overlayOpacity: 0.7
  property color card: "#1D1D1D"
  property color modalSurface: card
  property Gradient modalGradient: null
  property color modalBorder: panelBorder
  property color sessionControl: Qt.rgba(1, 1, 1, 0.07)
  property color menuCard: card
  property color menuControl: card
  property color menuCardHover: Qt.tint(card, rowHover)
  property Gradient menuCardHoverGradient: null
  property color trayHover: rowHover

  property color notificationHover: Qt.rgba(1, 1, 1, 0.06)
  property color notificationText: "#F8F9F9"
  property color notificationTitle: notificationText
  property color notificationCloseFill: sidebarControl
  property color notificationCloseHover: "#3D3D3D"
  property color dismissGlyph: "#38224D"
  property color dismissHoverGlyph: "black"
  property color inlineFill: "#242424"
  property color inlineHoverFill: "#313131"

  property color sidebarCardFill: Qt.rgba(0, 0, 0, 0.10)
  property color sidebarCardOutline: Qt.rgba(1, 1, 1, 0.10)
  property color sidebarHoverFill: Qt.rgba(1, 1, 1, 0.04)
  property color sidebarCardHoverFill: Qt.tint(sidebarCardFill, sidebarHoverFill)
  property color sidebarClearFill: Qt.rgba(1, 1, 1, 0)
  property color sidebarBackground: "#1D1D1D"
  property color sidebarBorder: "#303030"
  property color sidebarDivider: "#383838"
  property color sidebarWorkspaceActive: "#242424"
  property color sidebarControl: "#303030"
  property color sidebarForeground: "#F8F9F9"
  property color sidebarInnerOutline: sidebarControl
  property color sidebarSliderTrack: sliderTrack
  property color sidebarButtonSelected: "#303030"
  property color sidebarButtonHover: "#262626"
  property color sidebarButtonRest: Qt.rgba(38 / 255, 38 / 255, 38 / 255, 0)
  property color feedbackDotOff: border
  property color clockChipBorder: outline
  property color installHover: "#262626"

  property color workspaceLauncherActive: "#262626"
  property color workspaceActiveIndicatorColor: "#262626"
  property color workspaceCollapsedActive: workspaceActiveIndicatorColor
  property color workspaceActiveRing: sidebarBorder
  property color workspaceIconOutline: sidebarInnerOutline
  property color workspaceControlHover: sidebarControl
  property color workspacePlaceholderColor: sidebarInnerOutline
  property color workspaceDropFill: "#191919"
  property color workspaceDropStroke: "#4F3D64"
  property color workspaceNumberText: sidebarForeground
  property color workspaceNumberBackground: sidebarWorkspaceActive
  property color workspaceNumberDragBackground: sidebarControl
  property color workspaceDragBackground: "#292929"
}
