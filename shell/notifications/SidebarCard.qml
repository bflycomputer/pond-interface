import QtQuick
import Quickshell.Widgets
import "." as Notifications
import ".." as Shell

Item {
  id: root
  property real collapseProgress: 0
  readonly property bool empty: Notifications.State.notificationCount === 0
  signal panelRequested
  property real transientProgress: Notifications.State.transientVisible ? 1 : 0
  readonly property real inlineAmount: transientProgress * (1 - Shell.Theme.collapseHeight(collapseProgress))
  readonly property real previewOpacity: inlineAmount >= 0.54 ? 1 : 0
  readonly property var notification: Notifications.State.currentTransient
  implicitHeight: 48 + (47 + preview.height - 48) * inlineAmount
  Behavior on transientProgress { Shell.Motion {} }

  Shell.Card {
    anchors.fill: parent
    radius: root.empty ? 12 : Shell.Theme.sidebarCardRadius
    Item {
      id: summary
      width: parent.width
      height: 48

      implicitHeight: Shell.Theme.sidebarSimpleRowHeight

      Item {
        id: primary
        width: Notifications.Style.summaryIconSize + (root.empty ? 0 : 2 + caption.implicitWidth)
        x: Math.round(Shell.Theme.lerp(
            Shell.Theme.sidebarRowHorizontalPadding,
            (summary.width - width) / 2,
            Shell.Theme.collapseWidth(root.collapseProgress)))
        y: Math.round((Shell.Theme.sidebarSimpleRowHeight - height) / 2)
        height: Notifications.Style.summaryIconSize

        Image {
          width: Notifications.Style.summaryIconSize
          height: Notifications.Style.summaryIconSize
          source: Qt.resolvedUrl("../assets/bell.svg")
          opacity: root.empty ? 0.88 : 1
          sourceSize: Qt.size(Notifications.Style.summaryIconSize * 2,
                              Notifications.Style.summaryIconSize * 2)
          fillMode: Image.PreserveAspectFit
          smooth: true
          antialiasing: true
        }

        Text {
          id: caption
          x: Notifications.Style.summaryIconSize + (root.empty ? 8 : 2)
          y: root.empty ? 3 + metrics.capitalHeight - baselineOffset : 0
          height: Notifications.Style.summaryIconSize
          text: root.empty ? "Notifications" : String(Notifications.State.notificationCount)
          visible: !root.empty || root.collapseProgress < 0.31
          opacity: root.empty ? 0.6 : 1
          color: Notifications.Style.foreground
          font.family: Shell.Theme.fontFamily
          font.weight: Font.Medium
          font.pixelSize: 13
          verticalAlignment: Text.AlignVCenter
          FontMetrics { id: metrics; font: caption.font }
        }
      }

      Row {
        id: applications
        x: primary.x + primary.width + 8
        y: primary.y
        width: Math.max(0, summary.width - x - Shell.Theme.sidebarRowHorizontalPadding)
        height: Notifications.Style.summaryIconSize
        spacing: 8
        opacity: root.collapseProgress < 0.31 ? 1 : 0
        visible: !root.empty && opacity > 0.001

        Rectangle {
          width: 1
          height: Notifications.Style.summaryIconSize
          color: Notifications.Style.divider
        }

        Repeater {
          // Show whole icons only, leaving the same right inset as the bell's left.
          model: Notifications.State.recentApps.slice(0, Math.max(0, Math.floor(
              (applications.width - 1) / (Notifications.Style.summaryIconSize + applications.spacing))))

          delegate: IconImage {
            required property var modelData
            required property int index

            width: Notifications.Style.summaryIconSize
            height: Notifications.Style.summaryIconSize
            source: modelData.iconSource || ""
            asynchronous: true
            smooth: true
            opacity: index === 0 ? 1 : Notifications.Style.secondaryIconOpacity
          }
        }
      }
    }

    Notifications.Card {
      id: preview
      y: 47 + (1 - root.previewOpacity) * 4
      width: root.width
      inlinePreview: true
      notification: root.notification
      closeEnabled: false
      extraHovered: inlineClose.hovered
      opacity: root.previewOpacity
      enabled: root.notification !== null && root.inlineAmount > 0.5
      onActivated: Notifications.State.activate(root.notification)
    }
  }

  MouseArea {
    width: parent.width
    height: 48
    enabled: !root.empty
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: root.panelRequested()
  }

  Notifications.CloseButton {
    id: inlineClose
    x: root.width - 16
    y: 60
    z: 3
    opacity: preview.hovered && root.inlineAmount > 0.7 ? 1 : 0
    visible: opacity > 0.001
    enabled: opacity > 0.5
    onClicked: Notifications.State.remove(root.notification)
  }
}
