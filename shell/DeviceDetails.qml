pragma ComponentBehavior: Bound
import QtQuick


// Shared Wi-Fi/Bluetooth details layout. Data and actions belong to the caller.
Item {
  id: root
  property var stackController
  property var selection: ({})
  property bool interactive: true
  property string title: ""
  property var detailRows: []
  property Component titleIcon
  property string primaryText: "Forget"
  property string secondaryText: "Disconnect"
  property bool primaryEnabled: true
  property bool secondaryEnabled: true
  property string message: ""
  signal primaryClicked
  signal secondaryClicked
  implicitWidth: PanelStyle.width
  implicitHeight: 120 + detailRows.length * 50 + (message ? 40 : 0)

  PanelBackground {
    anchors.fill: parent
    Text {
      x: 19.5; y: 19.5; width: root.titleIcon ? 245 : 276
      elide: Text.ElideRight
      text: root.title; color: "white"
      font.family: Theme.titleFontFamily; font.weight: Font.Normal; font.pixelSize: 20
    }
    Loader { x: 275.5; y: 23.5; width: 20; height: 20; sourceComponent: root.titleIcon }
    Column {
      x: 19.5; y: 75.5; spacing: 20
      Repeater {
        model: root.detailRows
        delegate: DetailLine {
          required property var modelData
          label: modelData.label
          value: String(modelData.value)
        }
      }
    }
    Text {
      x: 20; y: parent.height - 88; width: 276; height: 36
      visible: root.message !== ""; text: root.message
      wrapMode: Text.Wrap; color: PanelStyle.accent
      font.family: Theme.fontFamily; font.pixelSize: 12
    }
    ActionButton {
      x: 7.5; y: parent.height - 48.5
      text: root.primaryText
      interactive: root.interactive && root.primaryEnabled
      onClicked: root.primaryClicked()
    }
    ActionButton {
      x: 161.5; y: parent.height - 48.5
      text: root.secondaryText
      interactive: root.interactive && root.secondaryEnabled
      onClicked: root.secondaryClicked()
    }
  }
}
