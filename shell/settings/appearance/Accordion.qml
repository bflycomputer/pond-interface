import QtQuick
import "../.." as Shell

Rectangle {
  id: root
  default property alias content: body.data
  property string title
  property string summary
  property bool expanded: false
  property real expandedHeight: 100
  signal toggled
  implicitHeight: expanded ? expandedHeight : 50
  radius: 16
  color: header.containsMouse || activeFocus ? "#303030" : "#262626"
  clip: true
  activeFocusOnTab: true
  Accessible.role: Accessible.Button
  Accessible.name: title + ", " + summary + (expanded ? ", expanded" : ", collapsed")
  Accessible.onPressAction: toggled()
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
    text: root.title; color: "#b3b3b3"
    font.family: Shell.Theme.fontFamily; font.pixelSize: 15
    verticalAlignment: Text.AlignVCenter
  }
  Text {
    x: parent.width * 0.48; y: 0; width: parent.width - x - 40; height: 50
    text: root.summary; color: "#b3b3b3"
    font.family: Shell.Theme.fontFamily; font.pixelSize: 15
    verticalAlignment: Text.AlignVCenter; horizontalAlignment: Text.AlignRight
    elide: Text.ElideRight
  }
  Image {
    x: parent.width - 36; y: 17; width: 16; height: 16
    source: Qt.resolvedUrl("../../assets/appearance/chevron.svg")
    rotation: root.expanded ? 180 : 0
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
    opacity: root.expanded ? 1 : 0
    visible: opacity > 0
    Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
  }
}
