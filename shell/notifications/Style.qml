pragma Singleton
import QtQuick
import ".." as Shell

QtObject {
  readonly property int panelWidth: 280
  readonly property int interactiveWidth: 288
  readonly property int rowHeight: 92
  readonly property int panelHeaderHeight: 60
  readonly property int panelMaxHeight: 647
  readonly property int desktopMargin: 10
  readonly property int radius: 16
  readonly property int contentPadding: 16
  readonly property int summaryIconSize: 14
  readonly property int closeSize: 24
  readonly property int closeIconSize: 16
  readonly property color hover: Shell.Theme.colors.notificationHover
  readonly property color closeFill: Shell.Theme.colors.notificationCloseFill
  readonly property color closeHover: Shell.Theme.colors.notificationCloseHover
  readonly property color foreground: Shell.Theme.colors.notificationText
  readonly property color divider: Qt.rgba(1, 1, 1, 0.1)
  readonly property real secondaryIconOpacity: 0.4
  readonly property int panelDuration: 180
}
