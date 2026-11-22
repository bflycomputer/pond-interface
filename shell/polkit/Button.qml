import QtQuick
import ".." as Shell

// Pill button matching the wifi "Connect" button.
Rectangle {
  id: root
  property string text
  property bool primary: false
  property bool interactive: true
  // Not clickable, but shown at full strength (e.g. "Checking…").
  property bool busy: false
  signal clicked

  implicitWidth: 134
  implicitHeight: 44
  radius: height / 2
  antialiasing: true
  opacity: interactive || busy ? 1 : 0.4
  color: primary
      ? (hover.hovered ? Qt.lighter(Shell.PanelStyle.accent, 1.08) : Shell.PanelStyle.accent)
      : (hover.hovered ? Shell.PanelStyle.drawerHover : Shell.PanelStyle.drawerFill)

  Behavior on color { ColorAnimation { duration: Shell.PanelStyle.controlDuration } }
  Behavior on opacity { NumberAnimation { duration: Shell.PanelStyle.controlDuration } }

  Text {
    anchors.centerIn: parent
    text: root.text
    color: root.primary ? Shell.PanelStyle.accentText : Shell.Theme.colors.text
    opacity: root.primary ? 1 : 0.8
    font.family: Shell.Theme.fontFamily
    font.weight: Font.Medium
    font.pixelSize: 14
  }

  HoverHandler {
    id: hover
    enabled: root.interactive
    cursorShape: Qt.PointingHandCursor
  }
  TapHandler {
    enabled: root.interactive
    onTapped: root.clicked()
  }
}
