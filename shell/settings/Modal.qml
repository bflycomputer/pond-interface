import QtQuick
import QtQuick.Effects
import "." as Settings
import ".." as Shell

// Centered settings page with a fixed header and scrolling body.
Rectangle {
  id: root
  default property alias content: body.contentItem.data
  property string title
  property real bodyTop: 82
  property real titleOpacity: 1
  property string closeLabel: "Back to settings"
  property alias overlay: overlays.data
  property alias scrollItem: body
  property real contentHeight: 0
  property real availableHeight: 900
  property bool roundedContent: false
  property real closeButtonY: -13
  signal backRequested
  implicitWidth: 580
  implicitHeight: Math.min(contentHeight + bodyTop, availableHeight)
  radius: 32
  color: Settings.Style.card

  // Accordion heights already animate. Follow them directly so the shell and
  // hit targets stay in step instead of starting another animation each frame.
  // Stop dialog clicks from reaching the outside-dismiss area.
  MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons }
  Text {
    x: 30; y: 20
    text: root.title
    opacity: root.titleOpacity
    color: "white"
    font.family: Shell.Theme.titleFontFamily
    font.pixelSize: 32
    font.letterSpacing: -0.64
  }
  Flickable {
    id: body
    objectName: "settingsModalScroll"
    x: 0; y: root.bodyTop
    width: parent.width
    height: Math.max(0, parent.height - y)
    contentHeight: root.contentHeight
    clip: true
    boundsBehavior: Flickable.StopAtBounds
    interactive: contentHeight > height
    Shell.ScrollWheel { view: body }
    layer.enabled: root.roundedContent
    layer.smooth: true
    layer.effect: MultiEffect {
      autoPaddingEnabled: false
      maskEnabled: true
      maskThresholdMin: 0.5
      maskSpreadAtMin: 1.0
      maskSource: ShaderEffectSource {
        sourceItem: Rectangle {
          width: body.width; height: body.height
          radius: root.radius
          color: "white"
          antialiasing: true
        }
      }
    }
  }
  Item { id: overlays; anchors.fill: parent; z: 4 }
  Shell.PanelCloseButton {
    objectName: "settingsModalClose"
    x: parent.width - 20; y: root.closeButtonY; z: 5
    Accessible.role: Accessible.Button
    Accessible.name: root.closeLabel
    activeFocusOnTab: true
    Keys.onReturnPressed: root.backRequested()
    Keys.onSpacePressed: root.backRequested()
    onClicked: root.backRequested()
  }
}
