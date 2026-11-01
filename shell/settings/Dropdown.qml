pragma ComponentBehavior: Bound
import QtQuick
import ".." as Shell
import QtQuick.Controls
FocusScope {
  id: root
  property var options: []
  property real maximumHeight: 256
  property string currentValue
  signal selected(string value)
  signal dismissed
  function pick(option) { if (!option.disabled) selected(String(option.value)); }
  width: 276
  height: Math.min(maximumHeight, options.reduce((total, option) => total + (option.separator ? 9 : 40), 16))
  Shell.Shadow { anchors.fill: parent; cornerRadius: 16; shadows: Shell.PanelStyle.controlShadows }
  Rectangle {
    anchors.fill: parent; color: "#1d1d1d"; radius: 16
    border.width: 0.5; border.color: "#3d3d3d"
    MouseArea { anchors.fill: parent }
    ListView {
      id: list
      clip: true
      boundsBehavior: Flickable.StopAtBounds
      Shell.ScrollWheel { view: list }
      objectName: "displayOptions"
      x: 8; y: 8; width: parent.width - 16; height: parent.height - 16
      model: root.options
      focus: true; keyNavigationEnabled: true
      currentIndex: Math.max(0, root.options.findIndex(o => String(o.value) === root.currentValue))
      onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)
      Component.onCompleted: positionViewAtIndex(currentIndex, ListView.Contain)
      function step(move) {
        let previous;
        do {
          previous = currentIndex;
          move();
        } while (currentIndex !== previous && root.options[currentIndex].disabled);
      }
      Keys.onEscapePressed: root.dismissed()
      Keys.onReturnPressed: root.pick(root.options[currentIndex])
      Keys.onSpacePressed: root.pick(root.options[currentIndex])
      Keys.onUpPressed: step(decrementCurrentIndex)
      Keys.onDownPressed: step(incrementCurrentIndex)
      ScrollBar.vertical: ScrollBar { width: 3; policy: ScrollBar.AsNeeded }
      delegate: Rectangle {
        id: option
        required property var modelData
        required property int index
        objectName: "displayOption" + modelData.value
        width: list.width; height: modelData.separator ? 9 : 40; radius: 12
        color: !modelData.disabled && (hover.hovered || (list.activeFocus && list.currentIndex === index) || String(modelData.value) === root.currentValue) ? Shell.PanelStyle.rowHover : "transparent"
        Accessible.role: modelData.separator ? Accessible.Separator : Accessible.MenuItem; Accessible.name: modelData.label
        Accessible.checked: !!modelData.checked
        Accessible.onPressAction: root.pick(modelData)
        Text {
          x: 12; width: parent.width - (trailing.visible ? 52 : 24); anchors.verticalCenter: parent.verticalCenter
          text: option.modelData.label; elide: Text.ElideRight
          color: "white"; opacity: option.modelData.disabled ? 0.3 : 1
          font.family: Shell.Theme.fontFamily; font.pixelSize: 13; font.weight: Font.Medium
        }
        Image {
          id: trailing
          visible: !!option.modelData.submenu || !!option.modelData.checked
          x: parent.width - 28; anchors.verticalCenter: parent.verticalCenter
          width: 16; height: 16; sourceSize: Qt.size(32, 32)
          rotation: option.modelData.submenu ? -90 : 0
          source: Qt.resolvedUrl(option.modelData.submenu ? "../assets/appearance/chevron.svg" : "../assets/installs/check.svg")
        }
        Rectangle {
          visible: !!option.modelData.separator
          anchors.centerIn: parent
          width: parent.width - 24; height: 1
          color: Shell.Theme.sidebarV3Divider
        }
        HoverHandler { id: hover; cursorShape: option.modelData.disabled ? Qt.ArrowCursor : Qt.PointingHandCursor }
        TapHandler { onTapped: root.pick(option.modelData) }
      }
    }
  }
}
