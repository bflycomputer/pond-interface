import QtQuick

Item {
  id: root
  property string themeKey
  property string label
  property bool selected: false
  property bool available: true
  readonly property bool hovered: pointer.containsMouse || activeFocus
  // Retarget from the current values when hover or selection interrupts motion.
  property real emphasis: available && (hovered || selected) ? 1 : 0
  property real selection: selected ? 1 : 0
  readonly property real idleRotation: themeKey === "daylight" ? 45 : 90
  readonly property real idleScale: themeKey === "daylight" ? 40 / 56 : 40 / 78
  Behavior on emphasis { NumberAnimation { duration: 250; easing.type: Easing.InOutCubic } }
  Behavior on selection { NumberAnimation { duration: 250; easing.type: Easing.InOutCubic } }
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
    source: root.available ? Qt.resolvedUrl("../../assets/appearance/" + root.themeKey + "-idle-background.svg") : ""
    opacity: 1 - root.emphasis
  }
  Image {
    x: 2; y: 2; width: 90; height: 90
    source: root.available ? Qt.resolvedUrl("../../assets/appearance/" + root.themeKey + "-hover-background.svg") : ""
    opacity: root.emphasis * (1 - root.selection)
  }
  Image {
    anchors.fill: parent
    source: root.available ? Qt.resolvedUrl("../../assets/appearance/" + root.themeKey + "-selected-background.svg") : ""
    opacity: root.selection
  }
  Item {
    objectName: "themeSymbol"
    anchors.fill: parent
    visible: root.available
    // Only the symbol moves; the background disc and selection ring stay fixed.
    rotation: root.idleRotation * (1 - root.emphasis)
    scale: root.idleScale + (1 - root.idleScale) * root.emphasis
    opacity: (0.1 + 0.2 * root.emphasis) * (1 - root.selection) + root.selection
    Image {
      anchors.fill: parent
      source: root.available ? Qt.resolvedUrl("../../assets/appearance/" + root.themeKey + "-symbol-white.svg") : ""
    }
    Image {
      anchors.fill: parent
      source: root.available ? Qt.resolvedUrl("../../assets/appearance/" + root.themeKey + "-symbol-selected.svg") : ""
      opacity: root.selection
    }
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
