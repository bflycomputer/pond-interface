import QtQuick
import "." as Wifi
import ".."

Item {
  id: root
  readonly property bool headerDividerVisible: false
  property var stackController
  property bool interactive: true
  implicitWidth: PanelStyle.width
  implicitHeight: 112

  PanelBackground {
    anchors.fill: parent
    Text {
      anchors.centerIn: parent
      width: parent.width - 40
      horizontalAlignment: Text.AlignHCenter
      wrapMode: Text.Wrap
      text: Wifi.State.statusText
      color: Wifi.State.phase === "failed" ? PanelStyle.accent : "white"
      font.family: Theme.titleFontFamily
      font.weight: Font.Normal
      font.pixelSize: 20
    }
  }
}
