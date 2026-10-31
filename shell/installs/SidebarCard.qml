import QtQuick
import "." as Installs
import ".." as Shell
import "../updates" as Updates

Shell.Card {
  id: root
  property real collapseProgress: 0
  readonly property real widthProgress: Shell.Theme.collapseWidth(collapseProgress)
  readonly property int contentPadding: 4
  readonly property int rowHeight: Shell.Theme.sidebarCardCollapsedWidth - 2 * contentPadding
  readonly property int count: Installs.State.jobs.count
  implicitWidth: Shell.Theme.lerp(Shell.Theme.sidebarCardExpandedWidth,
      Shell.Theme.sidebarCardCollapsedWidth, widthProgress)
  implicitHeight: count === 0 ? 0
      : 2 * contentPadding + count * rowHeight
  visible: count > 0
  radius: Shell.Theme.lerp(12, Shell.Theme.sidebarCardRadius, widthProgress)

  Repeater {
    model: Installs.State.jobs
    delegate: Item {
      id: row
      required property int index
      required property string jobId
      required property string name
      required property string status
      required property real progress
      required property string icon
      readonly property bool canLaunch: status === "installed" && jobId !== "system-update"
          && Installs.State.findApp(name) !== null
      readonly property bool showDismiss: dismiss.visible && (rowHover.hovered || dismiss.hovered)
      readonly property string summary: status === "installed" ? "Installed"
          : status === "failed" ? "Failed" : progress < 0 ? "Installing"
          : "Installing " + Math.round(progress * 100) + "%"
      y: root.contentPadding + index * root.rowHeight
      width: root.width
      height: root.rowHeight
      Accessible.role: Accessible.ListItem
      Accessible.name: jobId === "system-update" ? name : name + ": " + summary
      Accessible.onPressAction: Installs.State.dismiss(jobId)

      HoverHandler { id: rowHover }
      Item {
        x: root.contentPadding
        width: Math.max(0, parent.width - root.rowHeight - 2 * root.contentPadding)
        height: parent.height
        opacity: 1 - Shell.Theme.ramp(root.collapseProgress, 0, 0.3)
        HoverFill {
          anchors.fill: parent
          active: row.canLaunch && nameHover.hovered
        }
        Image {
          id: appIcon
          x: 12
          anchors.verticalCenter: parent.verticalCenter
          width: 16
          height: 16
          visible: status === Image.Ready
          source: row.icon
          sourceSize: Qt.size(32, 32)
          fillMode: Image.PreserveAspectFit
        }
        Text {
          x: appIcon.visible ? 36 : 12
          anchors.verticalCenter: parent.verticalCenter
          anchors.verticalCenterOffset: 1
          width: Math.max(0, parent.width - 12 - x)
          text: row.name
          textFormat: Text.PlainText
          elide: Text.ElideRight
          color: "white"
          font.family: Shell.Theme.fontFamily
          font.pixelSize: 13
          font.weight: Font.Medium
        }
        HoverHandler {
          id: nameHover
          cursorShape: row.canLaunch ? Qt.PointingHandCursor : Qt.ArrowCursor
        }
        TapHandler {
          enabled: row.canLaunch
          onTapped: Installs.State.launch(row.jobId)
        }
      }
      Installs.Indicator {
        id: indicator
        visible: (row.jobId !== "system-update" || row.status !== "installing") && !row.showDismiss
        x: dismiss.x + (dismiss.width - width) / 2
        y: (parent.height - height) / 2
        progress: row.progress
        status: row.status
      }
      Updates.Indicator {
        id: updateIndicator
        visible: row.jobId === "system-update" && row.status === "installing"
        x: indicator.x
        y: indicator.y
      }
      Shell.IconButton {
        id: dismiss
        visible: row.status !== "installing"
        opacity: row.showDismiss ? 1 : 0
        x: parent.width - width - root.contentPadding
        width: root.rowHeight
        height: parent.height
        iconSource: Qt.resolvedUrl("../assets/installs/cross.svg")
        iconWidth: 16
        iconHeight: 16
        onClicked: Installs.State.dismiss(row.jobId)
        HoverFill {
          anchors.fill: parent
          z: -1
          active: dismiss.hovered
        }
      }
    }
  }

  component HoverFill: Rectangle {
    property bool active
    radius: root.radius - root.contentPadding
    color: Shell.Theme.daylight ? Shell.Theme.sidebarHoverFill : "#262626"
    opacity: active ? 1 : 0
    Behavior on opacity { Shell.HoverAnimation {} }
  }
}
