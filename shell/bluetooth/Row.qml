import QtQuick
import ".." as Shell
Item {
  id: root
  property string label: ""
  property bool interactive: true
  property real labelRight: 260
  property real labelGap: 8
  property int labelSize: 13
  property real contentOpacity: 1
  property Component leading
  property Component trailing
  readonly property bool hovered: hover.hovered
  signal clicked
  implicitWidth: Shell.PanelStyle.rowWidth
  implicitHeight: Shell.PanelStyle.rowHeight

  Rectangle {
    anchors.fill: parent; radius: Shell.PanelStyle.rowRadius
    color: root.hovered ? Shell.PanelStyle.hover : "transparent"
  }
  MouseArea {
    anchors.fill: parent; enabled: root.interactive
    cursorShape: Qt.PointingHandCursor
    onClicked: root.clicked()
  }
  Loader {
    x: 12; y: 12; width: 20; height: 20
    sourceComponent: root.leading; opacity: root.contentOpacity
  }
  Text {
    x: 32 + root.labelGap
    anchors.verticalCenter: parent.verticalCenter
    width: Math.max(0, root.labelRight - x)
    elide: Text.ElideRight
    text: root.label; color: "white"; opacity: root.contentOpacity
    font.family: Shell.Theme.fontFamily; font.weight: Font.Medium; font.pixelSize: root.labelSize
  }
  Loader { anchors.fill: parent; sourceComponent: root.trailing }
  HoverHandler { id: hover; enabled: root.interactive; cursorShape: Qt.PointingHandCursor }
}
