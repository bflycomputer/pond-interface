pragma Singleton
import QtQuick

QtObject {
  readonly property color surface: "#1D1D1D"
  readonly property color backSurface: "#131313"
  readonly property color border: "#3D3D3D"
  readonly property color hover: "#262626"
  readonly property color pressed: "#303030"
  readonly property color accent: "#CBA6F7"
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
  readonly property color sliderFill: "#E7E7E7"
  readonly property color sliderBubble: "#D1D1D1"
  readonly property int audioRowHeight: 40
  readonly property int hoverExitDuration: 60
  readonly property int hoverCollapseDelay: 76
}
