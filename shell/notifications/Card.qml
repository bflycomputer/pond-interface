import QtQuick
import Quickshell.Widgets
import "." as Notifications
import ".." as Shell

Item {
  id: root
  property var notification: ({})
  property bool inlinePreview: false
  property bool showDivider: false
  property bool closeEnabled: true
  property bool extraHovered: false
  signal activated
  signal dismissed
  readonly property bool hovered: pointer.containsMouse || closeButton.hovered || extraHovered
  readonly property real surfaceWidth: inlinePreview ? width : 280
  readonly property int padding: inlinePreview ? 12 : 16
  readonly property int iconSize: inlinePreview ? 14 : 16
  readonly property int lineHeight: inlinePreview ? 17 : 16
  readonly property real targetHeight: inlinePreview
      ? Math.min(103, bodyText.y + bodyText.height + 12)
      : Math.max(76, Math.min(108, bodyText.y + bodyText.height + 16))
  property real animatedHeight: targetHeight
  implicitWidth: 288
  implicitHeight: animatedHeight
  Behavior on animatedHeight { Shell.Motion {} }

  Rectangle {
    width: root.surfaceWidth
    height: root.height
    radius: 16
    color: root.inlinePreview && Shell.Theme.daylight
        ? (root.hovered ? Shell.Theme.sidebarHoverFill : Shell.Theme.sidebarClearFill)
        : root.inlinePreview && root.hovered ? Notifications.Style.hover : Shell.Theme.sidebarV3Background
    antialiasing: true
    Behavior on color { ColorAnimation { duration: 120; easing.type: Easing.OutCubic } }
  }

  Rectangle {
    x: 4
    y: 4
    width: root.surfaceWidth - 8
    height: Math.max(0, root.height - 8)
    radius: 10
    color: Notifications.Style.hover
    opacity: !root.inlinePreview && root.hovered ? 1 : 0
    antialiasing: true
    Behavior on opacity { Shell.HoverAnimation {} }
  }

  IconImage {
    x: root.padding
    y: 16
    width: root.iconSize
    height: width
    source: Notifications.State.iconSource(root.notification || ({}))
    asynchronous: true
    smooth: true
  }

  Text {
    id: timeText
    x: root.surfaceWidth - root.padding - width
    y: 16
    height: root.inlinePreview ? 14 : 16
    text: root.notification ? Notifications.State.timeLabel(root.notification.timestamp || 0) : ""
    color: Notifications.Style.foreground
    opacity: 0.5
    font.family: Shell.Theme.fontFamily
    font.pixelSize: 13
    verticalAlignment: Text.AlignVCenter
  }

  Text {
    x: root.padding + root.iconSize + 4
    y: 16
    width: Math.max(0, timeText.x - x - 8)
    height: timeText.height
    text: Notifications.State.title(root.notification)
    color: Notifications.Style.foreground
    opacity: 0.5
    elide: Text.ElideRight
    font.family: Shell.Theme.fontFamily
    font.pixelSize: 13
    verticalAlignment: Text.AlignVCenter
  }

  Text {
    id: bodyText
    x: root.padding
    y: root.inlinePreview ? 40 : 44
    width: root.surfaceWidth - root.padding * 2
    height: Math.min(root.lineHeight * 3, Math.max(root.lineHeight,
        root.inlinePreview ? implicitHeight : Math.round(implicitHeight / root.lineHeight) * root.lineHeight))
    text: Notifications.State.message(root.notification)
    color: Notifications.Style.foreground
    wrapMode: Text.Wrap
    maximumLineCount: 3
    elide: Text.ElideRight
    font.family: Shell.Theme.fontFamily
    font.weight: Font.Medium
    font.pixelSize: 13
    lineHeightMode: Text.FixedHeight
    lineHeight: root.lineHeight
  }

  Rectangle {
    x: 16
    y: root.height - 1
    width: root.surfaceWidth - 32
    height: 1
    color: Notifications.Style.divider
    visible: root.showDivider
  }

  MouseArea {
    id: pointer
    width: root.width
    height: root.height
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: root.activated()
  }

  Notifications.CloseButton {
    id: closeButton
    x: root.surfaceWidth - 16
    y: 16
    z: 2
    opacity: root.closeEnabled && root.hovered ? 1 : 0
    visible: opacity > 0.001
    enabled: opacity > 0.5
    Behavior on opacity { Shell.HoverAnimation {} }
    onClicked: root.dismissed()
  }
}
