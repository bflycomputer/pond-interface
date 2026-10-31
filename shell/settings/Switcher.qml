pragma ComponentBehavior: Bound
import QtQuick
import ".." as Shell

// Two-option switcher. Model entries are {key, label, width}.
Rectangle {
  id: root
  property var model: []
  property string current
  signal selected(string key)
  width: 168; height: 41; radius: 12
  color: "transparent"; border.width: 1; border.color: "#262626"
  Row {
    x: 2; y: 2
    Repeater {
      model: root.model
      delegate: Rectangle {
        id: option
        required property var modelData
        required property int index
        readonly property bool chosen: root.current === modelData.key
        objectName: root.objectName + modelData.key
        width: modelData.width; height: 37
        radius: 2
        topLeftRadius: index === 0 ? root.radius - 2 : 2; bottomLeftRadius: topLeftRadius
        topRightRadius: index === 1 ? root.radius - 2 : 2; bottomRightRadius: topRightRadius
        color: chosen ? "#303030" : hover.hovered || activeFocus ? "#262626" : "transparent"
        activeFocusOnTab: true
        Accessible.role: Accessible.RadioButton
        Accessible.name: modelData.label
        Accessible.checked: chosen
        Accessible.onPressAction: root.selected(modelData.key)
        Keys.onReturnPressed: root.selected(modelData.key)
        Keys.onSpacePressed: root.selected(modelData.key)
        Text {
          anchors.centerIn: parent
          text: option.modelData.label; color: "white"
          opacity: hover.hovered ? 1 : 0.7
          font.family: Shell.Theme.fontFamily; font.pixelSize: 13
        }
        HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
        TapHandler { onTapped: root.selected(option.modelData.key) }
      }
    }
  }
}
