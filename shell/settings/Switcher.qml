pragma ComponentBehavior: Bound
import QtQuick
import ".." as Shell

// Option switcher. Model entries are {key, label, width}.
Rectangle {
  id: root
  property var model: []
  property string current
  property bool framed: true
  readonly property int inset: framed ? 2 : 0
  signal selected(string key)
  width: options.width + 2 * inset; height: 37 + 2 * inset; radius: 12
  color: framed ? "transparent" : Shell.PanelStyle.controlFill
  border.width: framed ? 1 : 0; border.color: Shell.PanelStyle.outline
  Row {
    id: options
    x: root.inset; y: root.inset
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
        topLeftRadius: index === 0 ? root.radius - root.inset : 2; bottomLeftRadius: topLeftRadius
        topRightRadius: index === root.model.length - 1 ? root.radius - root.inset : 2; bottomRightRadius: topRightRadius
        color: chosen ? Shell.PanelStyle.controlHover : hover.hovered || activeFocus ? Shell.PanelStyle.rowHover : "transparent"
        activeFocusOnTab: true
        Accessible.role: Accessible.RadioButton
        Accessible.name: modelData.label
        Accessible.checked: chosen
        Accessible.onPressAction: root.selected(modelData.key)
        Keys.onReturnPressed: root.selected(modelData.key)
        Keys.onSpacePressed: root.selected(modelData.key)
        Text {
          anchors.centerIn: parent
          text: option.modelData.label; color: Shell.Theme.colors.text
          opacity: hover.hovered ? 1 : 0.7
          font.family: Shell.Theme.fontFamily; font.pixelSize: 13
        }
        HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
        TapHandler { onTapped: root.selected(option.modelData.key) }
      }
    }
  }
}
