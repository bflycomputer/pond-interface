pragma Singleton
import QtQuick
import QtCore
import Quickshell
import Quickshell.Io
import "themes" as Themes

Singleton {
  id: root
  property string name: "daylight"
  readonly property var schemes: ({
    unthemed: unthemedScheme, daylight: daylightScheme,
    hazel: hazelScheme, wisteria: wisteriaScheme, north: northScheme
  })
  readonly property Themes.Unthemed colors: schemes[name]
  readonly property bool translucent: colors.translucent
  readonly property Themes.Unthemed unthemedScheme: Themes.Unthemed {}
  readonly property Themes.Daylight daylightScheme: Themes.Daylight {}
  readonly property Themes.Hazel hazelScheme: Themes.Hazel {}
  readonly property Themes.Wisteria wisteriaScheme: Themes.Wisteria {}
  readonly property Themes.North northScheme: Themes.North {}
  readonly property color sidebarCardOutline: colors.sidebarCardOutline
  readonly property color sidebarCardFill: colors.sidebarCardFill
  readonly property color sidebarCardHoverFill: colors.sidebarCardHoverFill
  readonly property color sidebarHoverFill: colors.sidebarHoverFill
  readonly property color sidebarClearFill: colors.sidebarClearFill

  function reload() { themeFile.reload(); }

  FileView {
    id: themeFile
    path: StandardPaths.writableLocation(StandardPaths.ConfigLocation) + "/pond-interface/theme.json"
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: {
      try {
        const theme = JSON.parse(text()).theme;
        root.name = Object.keys(schemes).includes(theme) ? theme : "daylight";
      } catch (error) { console.warn("Could not read theme selection:", error); }
    }
  }

  readonly property color sidebarInnerOutline: colors.sidebarInnerOutline
  readonly property int sidebarOuterMargin: 10
  readonly property int sidebarCardExpandedWidth: 156
  readonly property int sidebarCardCollapsedWidth: 48
  readonly property int sidebarCardRadius: 16
  readonly property int sidebarCardGap: 6
  readonly property int sidebarFadeWidth: 12
  readonly property int sidebarRowHorizontalPadding: 16
  readonly property int sidebarSimpleRowHeight: 48
  readonly property int sidebarTimeExpandedHeight: 58
  readonly property color sidebarBackground: colors.sidebarBackground
  readonly property color sidebarBorder: colors.sidebarBorder
  readonly property color sidebarDivider: colors.sidebarDivider
  readonly property color workspaceLauncherActive: colors.workspaceLauncherActive
  readonly property color workspaceActiveIndicatorColor: colors.workspaceActiveIndicatorColor
  readonly property color sidebarControl: colors.sidebarControl
  readonly property color sidebarForeground: colors.sidebarForeground
  readonly property color mediaHoverBackground: "#262626"
  readonly property color workspaceIconOutline: colors.workspaceIconOutline
  readonly property color workspaceControlHover: colors.workspaceControlHover
  readonly property color workspacePlaceholderColor: colors.workspacePlaceholderColor
  readonly property color workspaceDropFill: colors.workspaceDropFill
  readonly property color workspaceNumberBackground: colors.workspaceNumberBackground
  readonly property color workspaceNumberDragBackground: colors.workspaceNumberDragBackground
  readonly property color workspaceDragBackground: colors.workspaceDragBackground
  readonly property real workspaceDragGlyphScale: translucent ? 13.913043975830078 / 16 : 1
  readonly property int workspaceControlSize: 40
  readonly property int workspaceCollapsedControlSize: 32
  readonly property int workspaceControlGap: 8
  readonly property int workspaceControlPitch: workspaceControlSize + workspaceControlGap
  readonly property int workspaceRowGap: 10
  readonly property int workspaceRowPitch: workspaceControlSize + workspaceRowGap
  readonly property int workspaceCollapsedControlPitch:
      workspaceCollapsedControlSize + workspaceCollapsedControlGap
  readonly property int workspaceCollapsedControlGap: 8
  readonly property int workspaceContentPadding: (sidebarCardExpandedWidth
      - workspaceGridColumns * workspaceControlSize
      - (workspaceGridColumns - 1) * workspaceControlGap) / 2
  readonly property int workspaceActiveIndicatorInset: 5
  readonly property int workspaceIconSize: 16
  readonly property int workspaceGridColumns: 3
  readonly property int workspaceGridMinimumRows: 3
  readonly property int workspaceGridMinimumHeight: workspaceContentPadding * 2
      + workspaceGridMinimumRows * workspaceControlSize
      + (workspaceGridMinimumRows - 1) * workspaceRowGap
  readonly property int workspacePlaceholderDotSize: 4
  readonly property int workspaceCollapsedHeaderHeight: 37
  readonly property int sidebarHoverDuration: 120
  readonly property int sidebarWorkspaceSwitchDuration: 180
  readonly property int workspaceDragSnapDuration: 110
  readonly property int mediaControlSize: 20
  readonly property int mediaRevealDuration: 180
  readonly property int sidebarStrokeWidth: 1
  readonly property string fontFamily: "Onest"
  readonly property string titleFontFamily: "Pond Gramercy"
  readonly property string plexFontFamily: "IBM Plex Mono"

  function collapseWidth(progress) { return ramp(progress, 0, 0.56); }
  function collapseHeight(progress) { return ramp(progress, 0.56, 1); }

  function clamp01(value) { return Math.max(0, Math.min(1, value)); }
  function lerp(from, to, progress) {
    return from + (to - from) * clamp01(progress);
  }
  function ramp(progress, start, end) {
    return clamp01((progress - start) / (end - start));
  }
}
