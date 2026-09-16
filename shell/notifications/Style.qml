pragma Singleton
import QtQuick

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
  readonly property color hover: "#262626"
  readonly property color closeHover: "#3D3D3D"
  readonly property color foreground: "#F8F9F9"
  readonly property color divider: Qt.rgba(1, 1, 1, 0.1)
  readonly property real secondaryIconOpacity: 0.4
  readonly property int panelDuration: 180
}
