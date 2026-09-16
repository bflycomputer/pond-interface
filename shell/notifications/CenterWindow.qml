pragma ComponentBehavior: Bound
import QtQuick
import Quickshell.Widgets
import Quickshell
import Quickshell.Wayland
import "." as Notifications
import ".." as Shell

// Focused notification pullout. The full-screen surface provides the window
// shade and outside-click dismissal; the 280px panel itself remains aligned
// to the live sidebar edge in both expanded and collapsed states.
PanelWindow {
  id: root

  required property var bar

  readonly property string outputName: bar && bar.screen ? bar.screen.name : ""
  readonly property bool requested: Notifications.State.panelOpen
      && Notifications.State.panelOutputName === outputName
  property real reveal: requested ? 1 : 0
  readonly property int itemCount: Notifications.State.notificationCount
  readonly property bool listMode: itemCount >= 2
  property real measuredListHeight: 0
  property int measuredItemCount: -1
  readonly property real effectiveListHeight:
      measuredItemCount === itemCount && measuredListHeight > 0
      ? measuredListHeight : itemCount * Notifications.Style.rowHeight
  readonly property real panelHeight: listMode
      ? Math.min(Notifications.Style.panelHeaderHeight
                 + effectiveListHeight,
                 Notifications.Style.panelMaxHeight)
      : effectiveListHeight
  readonly property real panelLeft: Shell.Theme.sidebarOuterMargin + bar.cardWidth
      + Notifications.Style.desktopMargin
  readonly property real panelTop: panelHeight >= Notifications.Style.panelMaxHeight
      ? Notifications.Style.desktopMargin
      : Math.max(Notifications.Style.desktopMargin,
                 Math.min(bar.notificationCardCenterY - panelHeight / 2,
                          height - Notifications.Style.desktopMargin - panelHeight))
  readonly property real windowStart: panelLeft

  screen: bar.screen
  visible: requested || reveal > 0.001
  color: "transparent"

  anchors {
    left: true
    right: true
    top: true
    bottom: true
  }

  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.namespace: "pond-notification-center-"
      + (outputName || "unknown")
  WlrLayershell.exclusionMode: ExclusionMode.Ignore

  Behavior on reveal { Shell.Motion { duration: Notifications.Style.panelDuration } }

  Rectangle {
    x: root.windowStart
    y: Notifications.Style.desktopMargin
    width: Math.max(0, parent.width - x - Notifications.Style.desktopMargin)
    height: Math.max(0, parent.height - Notifications.Style.desktopMargin * 2)
    radius: 12
    color: Qt.rgba(0, 0, 0, 0.4 * root.reveal)
    antialiasing: true
  }

  MouseArea {
    anchors.fill: parent
    z: 1
    acceptedButtons: Qt.LeftButton
    onClicked: Notifications.State.closePanel()
  }

  MouseArea {
    x: root.panelLeft - (1 - root.reveal) * 4
    y: root.panelTop
    width: Notifications.Style.interactiveWidth
    height: root.panelHeight
    z: 2
    acceptedButtons: Qt.LeftButton
    onClicked: mouse => mouse.accepted = true
  }

  Rectangle {
    id: panelBackground
    x: root.panelLeft - (1 - root.reveal) * 4
    y: root.panelTop
    width: Notifications.Style.panelWidth
    height: root.panelHeight
    radius: Notifications.Style.radius
    color: Shell.Theme.sidebarV3Background
    opacity: root.reveal
    antialiasing: true
    z: 2
    visible: root.listMode
  }

  Text {
    x: panelBackground.x + Notifications.Style.contentPadding
    y: panelBackground.y + Notifications.Style.contentPadding
    height: 28
    text: root.itemCount + " Notifications"
    color: Notifications.Style.foreground
    font.family: Shell.Theme.titleFontFamily
    font.weight: Font.Normal
    font.pixelSize: 20
    visible: root.listMode
    opacity: root.reveal
    z: 3
  }

  Text {
    id: clearAll
    x: panelBackground.x + Notifications.Style.panelWidth
       - Notifications.Style.contentPadding - width
    y: panelBackground.y + 21
    height: 19
    text: "Clear all"
    color: Notifications.Style.foreground
    opacity: root.listMode ? (clearPointer.containsMouse ? root.reveal
                                                         : root.reveal * 0.5) : 0
    font.family: Shell.Theme.fontFamily
    font.weight: Font.Medium
    font.pixelSize: 13
    visible: root.listMode && opacity > 0.001
    z: 4

    Behavior on opacity { Shell.HoverAnimation {} }

    MouseArea {
      id: clearPointer
      anchors.fill: parent
      anchors.margins: -8
      hoverEnabled: true
      acceptedButtons: Qt.LeftButton
      cursorShape: Qt.PointingHandCursor
      onClicked: Notifications.State.clearAll()
    }
  }

  Rectangle {
    x: panelBackground.x + Notifications.Style.contentPadding
    y: panelBackground.y + Notifications.Style.panelHeaderHeight
    width: Notifications.Style.panelWidth - Notifications.Style.contentPadding * 2
    height: 1
    color: Notifications.Style.divider
    opacity: root.reveal
    visible: root.listMode
    z: 3
  }

  ClippingRectangle {
    id: listClip
    x: root.panelLeft - (1 - root.reveal) * 4
    y: root.panelTop + (root.listMode ? 60 : 0)
    width: 280
    height: root.panelHeight - (root.listMode ? 60 : 0)
    color: "transparent"
    bottomLeftRadius: root.listMode ? 16 : 0
    bottomRightRadius: root.listMode ? 16 : 0
    opacity: root.reveal
    z: 3

    ListView {
      id: notificationList
      width: 288
      height: listClip.height
      clip: true
      model: Notifications.State.historyNotifications
      interactive: contentHeight > height
      boundsBehavior: Flickable.StopAtBounds
      onContentHeightChanged: {
        if (contentHeight > 0 || root.itemCount === 0) {
          root.measuredListHeight = contentHeight;
          root.measuredItemCount = root.itemCount;
        }
      }

      delegate: Notifications.Card {
        id: row
        required property var modelData
        required property int index

        width: Notifications.Style.interactiveWidth
        height: implicitHeight
        notification: modelData
        showDivider: root.listMode && index < root.itemCount - 1
        closeEnabled: false
        extraHovered: closeOverlay.hoveredCard === row && floatingClose.hovered
        onHoveredChanged: {
          if (hovered) closeOverlay.hoveredCard = row;
          else Qt.callLater(closeOverlay.releaseHover);
        }
        onActivated: Notifications.State.activate(modelData)
        onDismissed: Notifications.State.remove(modelData)
      }
    }
  }

  Item {
    id: closeOverlay
    property Item hoveredCard: null
    function releaseHover() {
      if (hoveredCard && !hoveredCard.hovered && !floatingClose.hovered)
        hoveredCard = null;
    }
    x: listClip.x
    y: listClip.y - 8
    width: 288
    height: listClip.height + 8
    clip: true
    opacity: root.reveal
    z: 4

    Notifications.CloseButton {
      id: floatingClose
      x: 264
      y: closeOverlay.hoveredCard
          ? closeOverlay.hoveredCard.y - notificationList.contentY + (root.listMode ? 0 : 24) : -height
      opacity: closeOverlay.hoveredCard ? 1 : 0
      visible: opacity > 0.001
      enabled: opacity > 0.5
      Behavior on opacity { Shell.HoverAnimation {} }
      onHoveredChanged: if (!hovered) Qt.callLater(closeOverlay.releaseHover)
      onClicked: Notifications.State.remove(closeOverlay.hoveredCard?.notification)
    }
  }
}
