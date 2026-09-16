import QtQuick

Item {
  id: root
  property string themeKey
  property string label
  property bool selected: false
  property bool available: true
  readonly property bool hovered: pointer.containsMouse || activeFocus
  signal clicked
  implicitWidth: 94; implicitHeight: 94
  activeFocusOnTab: true
  Accessible.role: Accessible.Button
  Accessible.name: available ? label : "Coming soon"
  Accessible.checkable: available
  Accessible.checked: selected
  Accessible.onPressAction: if (available) clicked()
  Keys.onReturnPressed: if (available) clicked()
  Keys.onSpacePressed: if (available) clicked()

  Image {
    x: 2; y: 2; width: 90; height: 90
    visible: root.available
    source: root.available ? Qt.resolvedUrl("../../assets/appearance/" + root.themeKey + "-idle.svg") : ""
  }
  Image {
    x: 2; y: 2; width: 90; height: 90
    source: root.available ? Qt.resolvedUrl("../../assets/appearance/" + root.themeKey + "-hover.svg") : ""
    opacity: root.hovered && !root.selected ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.InOutCubic } }
  }
  Image {
    anchors.fill: parent
    source: root.available ? Qt.resolvedUrl("../../assets/appearance/" + root.themeKey + "-selected.svg") : ""
    opacity: root.selected ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: 240; easing.type: Easing.InOutCubic } }
  }
  Rectangle {
    x: 2; y: 2; width: 90; height: 90; radius: 45
    visible: !root.available
    color: root.hovered ? "#171717" : "transparent"
    border.width: 1; border.color: "#262626"
    Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.InOutCubic } }
    Image {
      anchors.centerIn: parent; width: 32.156; height: 42.002; rotation: 90
      source: Qt.resolvedUrl("../../assets/appearance/coming-soon.svg")
    }
  }
  MouseArea {
    id: pointer; anchors.fill: parent; hoverEnabled: true
    cursorShape: root.available ? Qt.PointingHandCursor : Qt.ArrowCursor
    onClicked: if (root.available) root.clicked()
  }
}
