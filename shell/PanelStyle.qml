pragma Singleton
import QtQuick

QtObject {
  readonly property color surface: Theme.colors.surface
  readonly property color panelSurface: Theme.colors.panelSurface
  readonly property color backSurface: Theme.colors.backSurface
  readonly property color border: Theme.colors.border
  readonly property color panelBorder: Theme.colors.panelBorder
  readonly property Gradient panelGradient: Theme.colors.panelGradient
  readonly property Gradient modalGradient: Theme.colors.modalGradient
  readonly property color modalBorder: Theme.colors.modalBorder
  readonly property color hover: Theme.colors.hover
  readonly property color pressed: Theme.colors.pressed
  readonly property color controlFill: Theme.colors.controlFill
  readonly property color rowHover: Theme.colors.rowHover
  readonly property color sliderTrack: Theme.colors.sliderTrack
  readonly property color controlHover: Theme.colors.controlHover
  readonly property color outline: Theme.colors.outline
  readonly property color drawerFill: Theme.colors.drawerFill
  readonly property color drawerHover: Theme.colors.drawerHover
  readonly property color drawerRowHover: Theme.colors.drawerRowHover
  readonly property color drawerSliderTrack: Theme.colors.drawerSliderTrack
  readonly property color drawerSliderBorder: Theme.colors.drawerSliderBorder
  readonly property color fieldFocus: Theme.colors.fieldFocus
  readonly property color selectFill: Theme.colors.selectFill
  readonly property color checkFill: Theme.colors.checkFill
  readonly property color checkHover: Theme.colors.checkHover
  readonly property color checkMark: Theme.colors.checkMark
  readonly property color menuSurface: Theme.colors.menuSurface
  readonly property color menuBorder: Theme.colors.menuBorder
  readonly property color menuRowHover: Theme.colors.menuRowHover
  readonly property color closeFill: Theme.colors.closeFill
  readonly property color closeHover: Theme.colors.closeHover
  readonly property color closeBorder: Theme.colors.closeBorder
  readonly property color closeHoverBorder: Theme.colors.closeHoverBorder
  readonly property real drawerToggleAlpha: Theme.colors.drawerToggleAlpha
  readonly property color accent: Theme.colors.accent
  readonly property color accentText: "#4F3D64"
  readonly property color enabledSurface: "#0C3723"
  readonly property color enabledMark: "#B0FF4F"
  readonly property int width: 316
  readonly property int fieldWidth: 276
  readonly property int fieldHeight: 44
  readonly property int rowWidth: 300
  readonly property int rowHeight: 44
  readonly property int radius: 16
  readonly property int rowRadius: 12
  readonly property int pageDuration: 350
  readonly property int openDuration: 220
  readonly property int controlDuration: 120
  readonly property real blurRevealOpacity: 0.25
  readonly property var frontShadows: [
    { x: 0, y: -21, blur: 33.5, alpha: 0.06 },
    { x: 0, y: 23, blur: 27.5, alpha: 0.08 },
    { x: 0, y: -6, blur: 24.5, alpha: 0.12 },
    { x: 0, y: -2, blur: 23, alpha: 0.16 },
    { x: 0, y: 6, blur: 10, alpha: 0.19 }
  ]
  readonly property var backShadows: [
    { x: 0, y: -21, blur: 67, alpha: 0.06 },
    { x: 0, y: 23, blur: 55, alpha: 0.08 },
    { x: 0, y: -6, blur: 49, alpha: 0.12 },
    { x: 0, y: -2, blur: 46, alpha: 0.16 },
    { x: 0, y: 6, blur: 20, alpha: 0.19 }
  ]
  readonly property var controlShadows: [
    { x: 0, y: 97, blur: 33.5, alpha: 0.04 },
    { x: 0, y: 47, blur: 27.5, alpha: 0.06 },
    { x: 0, y: 12, blur: 24.5, alpha: 0.10 },
    { x: 0, y: 11, blur: 23, alpha: 0.13 },
    { x: 0, y: 9, blur: 10, alpha: 0.15 }
  ]
  readonly property color sliderFill: Theme.colors.sliderFill
  readonly property color sliderBubble: Theme.colors.sliderBubble
  readonly property int audioRowHeight: 40
  readonly property int hoverExitDuration: 60
  readonly property int hoverCollapseDelay: 76
}
