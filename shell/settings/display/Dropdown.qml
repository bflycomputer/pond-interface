pragma ComponentBehavior: Bound
import QtQuick
import "../.." as Shell
import QtQuick.Controls
Item {
  id: root
  property var options: []
  property real maximumHeight: 256
  property string currentValue
  signal selected(string value)
  signal dismissed
  width: 276
  height: Math.min(maximumHeight, options.length * 40 + 16)
  Shell.Shadow { anchors.fill: parent; cornerRadius: 16; shadows: Shell.PanelStyle.controlShadows }
  Rectangle {
    anchors.fill: parent; color: "#1d1d1d"; radius: 16
    border.width: 0.5; border.color: "#3d3d3d"
    MouseArea { anchors.fill: parent }
    ListView {
      id: list
      objectName: "displayOptions"
      x: 8; y: 8; width: parent.width - 16; height: parent.height - 16
      clip: true; boundsBehavior: Flickable.StopAtBounds
      model: root.options
      focus: true; keyNavigationEnabled: true
      currentIndex: Math.max(0, root.options.findIndex(o => String(o.value) === root.currentValue))
      onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)
      Component.onCompleted: positionViewAtIndex(currentIndex, ListView.Contain)
      Keys.onEscapePressed: root.dismissed()
      Keys.onReturnPressed: root.selected(String(root.options[currentIndex].value))
      Keys.onSpacePressed: root.selected(String(root.options[currentIndex].value))
      ScrollBar.vertical: ScrollBar { width: 3; policy: ScrollBar.AsNeeded }
      delegate: Rectangle {
        id: option
        required property var modelData
        required property int index
        objectName: "displayOption" + modelData.value
        width: list.width; height: 40; radius: 12
        color: hover.hovered || (list.activeFocus && list.currentIndex === index) || String(modelData.value) === root.currentValue ? "#262626" : "transparent"
        Accessible.role: Accessible.MenuItem; Accessible.name: modelData.label
        Accessible.onPressAction: root.selected(String(modelData.value))
        Text {
          x: 12; width: parent.width - 24; anchors.verticalCenter: parent.verticalCenter
          text: option.modelData.label; elide: Text.ElideRight
          color: "white"; font.family: Shell.Theme.fontFamily; font.pixelSize: 13; font.weight: Font.Medium
        }
        HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
        TapHandler { onTapped: root.selected(String(option.modelData.value)) }
      }
    }
  }
}
