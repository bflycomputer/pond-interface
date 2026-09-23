import QtQuick
import QtQuick.Controls
import "." as Installs
import ".." as Shell

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
      required property string message
      readonly property string summary: status === "installed" ? "Installed"
          : status === "failed" ? "Failed" : progress < 0 ? "Installing"
          : "Installing " + Math.round(progress * 100) + "%"
      y: Shell.Theme.lerp(8 + index * 32,
          (root.count === 1 ? 8 : 6) + index * 28, root.heightProgress)
      width: root.width
      height: 32
      Accessible.role: Accessible.ListItem
      Accessible.name: name + ": " + summary
      Accessible.onPressAction: Installs.State.dismiss(jobId)

      Text {
        x: Shell.Theme.sidebarRowHorizontalPadding
        anchors.verticalCenter: parent.verticalCenter
        width: Math.max(0, indicator.x - x - 8)
        text: row.name
        textFormat: Text.PlainText
        elide: Text.ElideRight
        color: "white"
        font.family: Shell.Theme.fontFamily
        font.pixelSize: 13
        font.weight: Font.Medium
        opacity: 1 - Shell.Theme.ramp(root.collapseProgress, 0, 0.3)
      }
      Installs.Indicator {
        id: indicator
        x: parent.width - 32
        y: 8
        progress: row.progress
        status: row.status
      }
      HoverHandler {
        id: hover
        cursorShape: row.status === "failed" ? Qt.PointingHandCursor : Qt.ArrowCursor
      }
      TapHandler {
        enabled: row.status === "failed"
        onTapped: Installs.State.dismiss(row.jobId)
      }
      ToolTip.visible: hover.hovered
      ToolTip.delay: 500
      ToolTip.text: row.name + ": " + row.summary
          + (row.status === "failed" ? "\n" + row.message + "\nClick to dismiss" : "")
    }
  }
}
