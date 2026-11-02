import QtQuick

Unthemed {
  translucent: true

  sidebarInnerOutline: Qt.rgba(1, 1, 1, 0.20)
  sidebarSliderTrack: sidebarInnerOutline
  sidebarButtonSelected: sidebarHoverFill
  sidebarButtonHover: sidebarHoverFill
  sidebarButtonRest: sidebarClearFill
  feedbackDotOff: sidebarInnerOutline
  clockChipBorder: sidebarInnerOutline
  sidebarDivider: sidebarCardOutline
  installHover: sidebarHoverFill
  inlineFill: Qt.tint(Qt.rgba(1, 1, 1, 0.10), sidebarClearFill)
  inlineHoverFill: Qt.tint(Qt.rgba(1, 1, 1, 0.10), sidebarHoverFill)

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
