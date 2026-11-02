import QtQuick
import QtQuick.Effects

Item {
  id: root
  required property var theme
  property bool selected: false
  readonly property bool hovered: pointer.containsMouse || activeFocus
  readonly property Gradient fill: theme.key === "daylight" ? daylightFill : null
  // Retarget from the current values when hover or selection interrupts motion.
  property real emphasis: hovered || selected ? 1 : 0
  property real selection: selected ? 1 : 0
  property color glyph: selected ? theme.activeGlyph : hovered ? theme.hoverGlyph : "white"
  Behavior on emphasis { NumberAnimation { duration: 250; easing.type: Easing.InOutCubic } }
  Behavior on selection { NumberAnimation { duration: 250; easing.type: Easing.InOutCubic } }
  Behavior on glyph { ColorAnimation { duration: 250; easing.type: Easing.InOutCubic } }
  signal clicked
  implicitWidth: 90; implicitHeight: 90
  activeFocusOnTab: true
  Accessible.role: Accessible.Button
  Accessible.name: theme.label
  Accessible.checkable: true
  Accessible.checked: selected
  Accessible.onPressAction: clicked()
  Keys.onReturnPressed: clicked()
  Keys.onSpacePressed: clicked()

  Gradient {
    id: daylightFill
    GradientStop { position: 0; color: "#496070" }
    GradientStop { position: 1; color: "#E7BDA7" }
  }
  Rectangle {
    anchors.fill: parent; radius: width / 2
    color: Qt.rgba(1, 1, 1, 0.1)
    opacity: 1 - root.emphasis
  }
  Rectangle {
    anchors.fill: parent; radius: width / 2
    color: root.theme.hoverFill
    gradient: root.fill
    opacity: root.emphasis * (1 - root.selection) * (root.fill ? 0.5 : 1)
  }
  Rectangle {
    anchors.fill: parent; radius: width / 2
    color: root.theme.activeFill
    gradient: root.fill
    opacity: root.selection
  }
  // Only the symbol moves; the background disc stays fixed.
  Image {
    objectName: "themeSymbol"
    anchors.centerIn: parent
    width: 52; height: 52
    source: Qt.resolvedUrl("../../assets/appearance/" + root.theme.key + "-symbol.svg")
    sourceSize: Qt.size(104, 104)
    rotation: root.theme.turn * (1 - root.emphasis)
    scale: (40 + 12 * root.emphasis) / 52
    opacity: 0.6 + 0.4 * root.emphasis
    layer.enabled: true
    layer.effect: MultiEffect { colorization: 1; colorizationColor: root.glyph }
  }
  MouseArea {
    id: pointer; anchors.fill: parent; hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: root.clicked()
  }
}
