import QtQuick


// Device drawer header, scrolling rows, empty state, and footer.
Item {
  id: root
  property var stackController
  property bool interactive: true
  property string title: ""
  property url titleIcon: ""
  property Component headerControl
  property var devices: []
  property Component deviceDelegate
  property Component footer
  property string emptyText: ""
  property string message: ""
  property int viewportHeight: 306
  property real listTop: 64
  property real listBottomPadding: 0
  readonly property alias contentY: deviceList.contentY
  implicitWidth: PanelStyle.width
  implicitHeight: viewportHeight + (message !== "" ? 44 : 0)

  PanelBackground {
    anchors.fill: parent
    Image {
      x: 19.5; y: 23.5; width: 20; height: 20
      visible: root.titleIcon.toString() !== ""; source: root.titleIcon
    }
    Text {
      x: root.titleIcon.toString() !== "" ? 43.5 : 19.5
      y: 19.5
      text: root.title; color: "white"
      font.family: Theme.titleFontFamily; font.weight: Font.Normal; font.pixelSize: 20
    }
    Loader { x: 241.5; y: 19.5; width: 54; height: 28; sourceComponent: root.headerControl }
    ScrollList {
      rowHeight: PanelStyle.rowHeight
      id: deviceList
      x: 8; y: root.listTop; width: PanelStyle.rowWidth
      height: root.viewportHeight - y - root.listBottomPadding
      model: root.devices
      delegate: root.deviceDelegate
      footer: root.footer
      footerPositioning: ListView.InlineFooter
    }
    Text {
      x: 20; y: root.listTop + (root.footer ? 52 : 16); width: 276
      text: root.emptyText; visible: deviceList.count === 0
      wrapMode: Text.Wrap; color: "white"; opacity: 0.5
      font.family: Theme.fontFamily; font.pixelSize: 13
    }
    Text {
      x: 20; y: root.viewportHeight; width: 276; height: 38
      text: root.message; visible: root.message !== ""
      wrapMode: Text.Wrap; color: PanelStyle.accent
      font.family: Theme.fontFamily; font.pixelSize: 12
    }
    ScrollShade {
      view: deviceList
      x: 0; y: root.listTop - 4; width: parent.width
    }
  }
}
