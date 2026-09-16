pragma Singleton
import QtQuick

QtObject {
  readonly property color sidebarInnerOutline: sidebarV3Control
  readonly property color sidebarControlHover: sidebarV3Control
  readonly property int sidebarOuterMargin: 10
  readonly property int sidebarCardExpandedWidth: 156
  readonly property int sidebarCardCollapsedWidth: 48
  readonly property int sidebarCardRadius: 16
  readonly property int sidebarCardGap: 6
  readonly property int sidebarRowHorizontalPadding: 16
  readonly property int sidebarSimpleRowHeight: 48
  readonly property int sidebarTimeExpandedHeight: 58
  readonly property color sidebarV3Background: "#1D1D1D"
  readonly property color sidebarV3Border: "#303030"
  readonly property color sidebarV3Divider: "#383838"
  readonly property color sidebarV3WorkspaceActive: "#242424"
  readonly property color workspaceLauncherActive: "#262626"
  readonly property color workspaceActiveIndicatorColor: "#262626"
  readonly property color sidebarV3Control: "#303030"
  readonly property color sidebarV3Foreground: "#F8F9F9"
  readonly property color mediaHoverBackground: "#262626"
  readonly property int workspaceControlSize: 40
  readonly property int workspaceCollapsedControlSize: 32
  readonly property int workspaceControlGap: 8
  readonly property int workspaceControlPitch: workspaceControlSize + workspaceControlGap
  readonly property int workspaceCollapsedControlPitch:
      workspaceCollapsedControlSize + workspaceCollapsedControlGap
  readonly property int workspaceCollapsedControlGap: 8
  readonly property int workspaceContentPadding: (sidebarCardExpandedWidth
      - workspaceGridColumns * workspaceControlSize
      - (workspaceGridColumns - 1) * workspaceControlGap) / 2
  readonly property int workspaceActiveIndicatorInset: 4
  readonly property int workspaceIconSize: 16
  readonly property int workspaceGridColumns: 3
  readonly property int workspaceGridMinimumRows: 3
  readonly property int workspaceGridMinimumHeight: workspaceContentPadding * 2
      + workspaceGridMinimumRows * workspaceControlSize
      + (workspaceGridMinimumRows - 1) * workspaceControlGap
  readonly property int workspacePlaceholderDotSize: 4
  readonly property int workspaceCollapsedHeaderHeight: 37
  readonly property int sidebarHoverDuration: 120
  readonly property int sidebarWorkspaceSwitchDuration: 180
  readonly property int mediaControlSize: 20
  readonly property int mediaRevealDuration: 180
  readonly property int sidebarStrokeWidth: 1
  readonly property string fontFamily: "Onest"
  readonly property string titleFontFamily: "ABC Gramercy"
  readonly property string plexFontFamily: "IBM Plex Mono"

  function clamp01(value) { return Math.max(0, Math.min(1, value)); }
  function lerp(from, to, progress) {
    return from + (to - from) * clamp01(progress);
  }
  function ramp(progress, start, end) {
    return clamp01((progress - start) / (end - start));
  }
}
