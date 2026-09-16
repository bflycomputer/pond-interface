import QtQuick
import ".."

Item {
  id: root
  property bool checked: false
  signal toggled(bool checked)

  implicitWidth: 54
  implicitHeight: 28

  Rectangle {
    anchors.fill: parent
    radius: 150
    color: "transparent"
    border.color: PanelStyle.border
    border.width: 1
    antialiasing: true
  }

  Rectangle {
    id: offButton
    x: 2
    y: 2
    width: 24
    height: 24
    radius: 200
    color: !root.checked ? PanelStyle.pressed
        : offHover.hovered ? PanelStyle.hover : "transparent"

    Rectangle {
      anchors.centerIn: parent
      width: 12
      height: 4
      radius: 2
      color: "transparent"
      border.color: Qt.rgba(0.91, 0.91, 0.91, 0.3)
      border.width: 1
    }
    HoverHandler { id: offHover; cursorShape: Qt.PointingHandCursor }
    TapHandler { onTapped: root.toggled(false) }
  }

  Rectangle {
    id: onButton
    x: 28
    y: 2
    width: 24
    height: 24
    radius: 200
    color: root.checked ? PanelStyle.enabledSurface
                        : onHover.hovered ? PanelStyle.hover : "transparent"

    Rectangle {
      anchors.centerIn: parent
      width: 4
      height: 12
      radius: 2
      color: root.checked ? PanelStyle.enabledMark
                          : Qt.rgba(0.91, 0.91, 0.91, 0.3)
    }
    HoverHandler { id: onHover; cursorShape: Qt.PointingHandCursor }
    TapHandler { onTapped: root.toggled(true) }
  }
}
