import QtQuick
import "../.." as Shell

Rectangle {
  id: root
  default property alias content: body.data
  property string title
  property string summary
  property bool navigation: false
  property bool expanded: false
  property real expandedHeight: 100
  signal toggled
  implicitHeight: expanded ? expandedHeight : 50
  radius: expanded ? 16 : 12
  color: header.containsMouse || activeFocus ? Shell.PanelStyle.controlHover : Shell.PanelStyle.controlFill
  clip: true
  activeFocusOnTab: true
  Accessible.role: Accessible.Button
  Accessible.name: title + ", " + summary + (navigation || !enabled ? "" : expanded ? ", expanded" : ", collapsed")
  Accessible.onPressAction: if (enabled) toggled()
  Keys.onReturnPressed: toggled()
  Keys.onSpacePressed: toggled()
  Behavior on implicitHeight {
    NumberAnimation { duration: 240; easing.type: Easing.InOutCubic }
  }
  Behavior on color {
    ColorAnimation { duration: 160; easing.type: Easing.OutCubic }
  }
  Text {
    x: 20; y: 0; height: 50
    text: root.title; color: "white"; opacity: 0.7
    font.family: Shell.Theme.fontFamily; font.pixelSize: 15
    verticalAlignment: Text.AlignVCenter
  }
  Text {
    x: parent.width * 0.48; y: 0; width: parent.width - x - (root.enabled ? 40 : 20); height: 50
    text: root.summary; color: "white"; opacity: 0.7
    font.family: Shell.Theme.fontFamily; font.pixelSize: 15
    verticalAlignment: Text.AlignVCenter; horizontalAlignment: Text.AlignRight
    elide: Text.ElideRight
  }
  Image {
    x: parent.width - 36; y: 17; width: 16; height: 16
    source: Qt.resolvedUrl("../../assets/appearance/chevron.svg")
    objectName: "settingsRowChevron"
    visible: root.enabled
    rotation: root.navigation ? -90 : root.expanded ? 180 : 0
    Behavior on rotation { NumberAnimation { duration: 220; easing.type: Easing.InOutCubic } }
  }
  MouseArea {
    id: header
    width: parent.width; height: 50
    hoverEnabled: true; cursorShape: Qt.PointingHandCursor
    onClicked: root.toggled()
  }
  Item {
    id: body
    x: 20; y: 50; width: parent.width - 40; height: root.expandedHeight - 50
    enabled: root.expanded
    visible: root.height > 50
  }
}
