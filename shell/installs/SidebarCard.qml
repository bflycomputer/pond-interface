import QtQuick
import "." as Installs
import ".." as Shell
import "../updates" as Updates

Shell.Card {
  id: root
  property real collapseProgress: 0
  readonly property real widthProgress: Shell.Theme.collapseWidth(collapseProgress)
  readonly property real heightProgress: Shell.Theme.collapseHeight(collapseProgress)
  readonly property int count: Installs.State.jobs.count
  implicitWidth: Shell.Theme.lerp(Shell.Theme.sidebarCardExpandedWidth,
      Shell.Theme.sidebarCardCollapsedWidth, widthProgress)
  implicitHeight: count === 0 ? 0 : Shell.Theme.lerp(48 + (count - 1) * 32,
      count === 1 ? 48 : 16 + count * 28, heightProgress)
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
      readonly property string summary: status === "installed" ? qsTrId("pond.installed")
          : status === "failed" ? qsTrId("pond.failed") : progress < 0 ? qsTrId("pond.installing")
          : qsTrId("pond.installing_1").arg(Math.round(progress * 100))
      y: Shell.Theme.lerp(8 + index * 32,
          (root.count === 1 ? 8 : 6) + index * 28, root.heightProgress)
      width: root.width
      height: 32
      Accessible.role: Accessible.ListItem
      readonly property string displayName: jobId !== "system-update" ? name
          : status === "installed" ? qsTrId("pond.update_complete")
          : status === "failed" ? qsTrId("pond.update_failed")
          : qsTrId("pond.updating")
      Accessible.name: jobId === "system-update" ? displayName : name + ": " + summary
      Accessible.onPressAction: Installs.State.dismiss(jobId)

      HoverHandler { id: rowHover }
      Item {
        x: 4
        y: -4
        width: Math.max(0, parent.width - 48)
        height: 40
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
          text: row.displayName
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
        x: parent.width - 32
        y: 8
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
        x: parent.width - 44
        width: 40
        height: parent.height
        iconSource: Qt.resolvedUrl("../assets/installs/cross.svg")
        iconWidth: 16
        iconHeight: 16
        onClicked: Installs.State.dismiss(row.jobId)
        HoverFill {
          y: -4
          width: parent.width
          height: 40
          z: -1
          active: dismiss.hovered
        }
      }
    }
  }

  component HoverFill: Rectangle {
    property bool active
    radius: 8
    color: Shell.Theme.daylight ? Shell.Theme.sidebarHoverFill : "#262626"
    opacity: active ? 1 : 0
    Behavior on opacity { Shell.HoverAnimation {} }
  }
}
