import QtQuick
import Quickshell
import Quickshell.Wayland
import "audio" as Audio
import "bluetooth" as Bluetooth
import "settings" as Settings
import "wifi" as Wifi
import "calendar" as Calendar
import "media" as Media
import "nirimap" as Nirimap
import "notifications" as Notifications
import "installs" as Installs
import Pond.Screenshot as Screenshot

PanelWindow {
  id: root
  required property bool expanded
  property bool calendarOpen: false
  property real collapseProgress: expanded ? 0 : 1
  signal toggleRequested
  readonly property real cardWidth: Theme.lerp(Theme.sidebarCardExpandedWidth,
      Theme.sidebarCardCollapsedWidth, Theme.collapseWidth(collapseProgress))
  readonly property real notificationCardCenterY: mainStack.y + notificationCard.y + 24
  property real siblingOpacity: Notifications.State.panelOpen
      && Notifications.State.panelOutputName === screen.name ? 0.6 : 1

  readonly property real panelX: Theme.sidebarOuterMargin + cardWidth + Theme.sidebarCardGap
  readonly property bool panelOpen: wifiPanel.opened || audioPanel.opened || bluetoothPanel.opened
  readonly property var activePanel: wifiPanel.opened ? wifiPanel : audioPanel.opened ? audioPanel : bluetoothPanel.opened ? bluetoothPanel : null
  property string pendingPanel: ""
  readonly property var panels: ({wifi: wifiPanel, audio: audioPanel, bluetooth: bluetoothPanel})

  function dismissPanels() {
    panelSwitchDelay.stop();
    pendingPanel = "";
    for (const panel of Object.values(panels)) panel.closeAll();
  }

  function togglePanel(name) {
    const panel = panels[name];
    if (!panel) return;
    const wasOpen = panel.opened;
    const wasVisible = Object.values(panels).some(item => item.visible);
    dismissPanels();
    if (wasOpen) return;
    Settings.State.close();
    calendarOpen = false;
    Notifications.State.closePanel();
    if (wasVisible) {
      pendingPanel = name;
      panelSwitchDelay.restart();
    } else panel.open();
  }

  Timer {
    id: panelSwitchDelay
    interval: 200
    onTriggered: {
      const panel = root.panels[root.pendingPanel];
      if (panel) panel.open();
      root.pendingPanel = "";
    }
  }

  Connections {
    target: Settings.State
    function onOpening() {
      root.dismissPanels();
      root.calendarOpen = false;
      Notifications.State.closePanel();
    }
  }
  Connections {
    target: Bluetooth.State
    function onPanelCommand(command, outputName) {
      if (outputName !== root.screen.name) return;
      if (command === "close") bluetoothPanel.closeAll();
      else if (command === "toggle" || !bluetoothPanel.opened) root.togglePanel("bluetooth");
    }
  }
  Connections {
    target: Audio.State
    function onKeyboardOutputVolumeChanged(value) {
      if (NiriMsg.focusedOutputName === "" || root.screen.name === NiriMsg.focusedOutputName)
        controls.showKeyboardVolume();
    }
  }

  color: "transparent"
  // Keep compositor resizes out of the card animation; only the input area shrinks.
  implicitWidth: Math.ceil(Math.max(Theme.sidebarOuterMargin + Theme.sidebarCardExpandedWidth + 8,
      wifiPanel.visible ? panelX + wifiPanel.width + 67 : 0,
      audioPanel.visible ? panelX + audioPanel.width + 67 : 0,
      bluetoothPanel.visible ? panelX + bluetoothPanel.width + 67 : 0))
  mask: Region {
    width: root.panelOpen ? root.implicitWidth : Math.ceil(Theme.sidebarOuterMargin + Math.max(root.cardWidth,
        workspacesCard.width, mediaCard.width, controls.width) + 8)
    height: root.height
  }
  anchors { left: true; top: true; bottom: true }
  WlrLayershell.layer: WlrLayer.Top
  WlrLayershell.namespace: "pond-sidebar"
  WlrLayershell.keyboardFocus: workspacesCard.dragSession.active
      ? WlrKeyboardFocus.Exclusive : panelOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
  WlrLayershell.exclusionMode: ExclusionMode.Normal
  exclusiveZone: Theme.sidebarOuterMargin + (expanded
      ? Theme.sidebarCardExpandedWidth : Theme.sidebarCardCollapsedWidth)
  Behavior on collapseProgress { Motion {} }
  Behavior on siblingOpacity { HoverAnimation { duration: 180 } }

  Column {
    id: mainStack
    x: Theme.sidebarOuterMargin
    y: Theme.sidebarOuterMargin
    spacing: Theme.sidebarCardGap

    Calendar.Clock {
      id: timeCard
      width: root.cardWidth
      collapseProgress: root.collapseProgress
      opacity: root.siblingOpacity
      onClicked: {
        root.dismissPanels();
        Notifications.State.closePanel();
        root.calendarOpen = !root.calendarOpen;
      }
    }

    Nirimap.Map {
      id: workspacesCard
      screen: root.screen
      collapseProgress: root.collapseProgress
      maximumHeight: Math.max(64,
          bottomStack.y - Theme.sidebarCardGap - mainStack.y
          - timeCard.height - mediaCard.height - notificationCard.height - installsCard.height
          - Theme.sidebarCardGap * (2 + (mediaCard.visible ? 1 : 0) + (installsCard.visible ? 1 : 0)))
      opacity: root.siblingOpacity
      onFocusRequested: index => NiriMsg.focusWorkspace(index)
      onWindowRequested: windowId => NiriMsg.focusWindow(windowId)
    }

    Media.Player {
      id: mediaCard
      collapseProgress: root.collapseProgress
      opacity: root.siblingOpacity
    }

    Notifications.SidebarCard {
      id: notificationCard
      width: root.cardWidth
      collapseProgress: root.collapseProgress
      onPanelRequested: { root.dismissPanels(); Notifications.State.togglePanel(root.screen.name); }
    }

    Installs.SidebarCard {
      id: installsCard
      width: root.cardWidth
      collapseProgress: root.collapseProgress
      opacity: root.siblingOpacity
    }
  }

  TapHandler {
    enabled: root.panelOpen
    acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
    gesturePolicy: TapHandler.DragThreshold
    property var panelAtPress: null
    onPressedChanged: if (pressed) panelAtPress = root.activePanel
    onTapped: eventPoint => {
      const panel = root.activePanel;
      if (!panel || panel !== panelAtPress) return;
      const x = eventPoint.position.x - panel.x;
      const y = eventPoint.position.y - panel.y;
      if (x < 0 || x > panel.width || y < 0 || y > panel.height)
        root.dismissPanels();
    }
  }

  Wifi.Panel {
    id: wifiPanel
    x: root.panelX
    z: 80
    anchors.bottom: parent.bottom
    anchors.bottomMargin: Theme.sidebarOuterMargin
  }

  Audio.Panel {
    id: audioPanel
    x: root.panelX
    z: 80
    anchors.bottom: parent.bottom
    anchors.bottomMargin: Theme.sidebarOuterMargin
  }

  Bluetooth.Panel {
    id: bluetoothPanel
    x: root.panelX
    z: 80
    anchors.bottom: parent.bottom
    anchors.bottomMargin: Theme.sidebarOuterMargin
  }

  Column {
    id: bottomStack
    x: Theme.sidebarOuterMargin
    anchors.bottom: parent.bottom
    anchors.bottomMargin: Theme.sidebarOuterMargin
    width: controls.width
    spacing: Theme.sidebarCardGap
    opacity: root.siblingOpacity
    Screenshot.Preview {
      width: root.cardWidth
      outputName: root.screen.name
      collapsed: root.collapseProgress > 0.5
    }
    BottomControls {
      id: controls
      collapseProgress: root.collapseProgress
      wifiOpen: wifiPanel.opened
      soundOpen: audioPanel.opened
      settingsOpen: Settings.State.opened && Settings.State.outputName === root.screen.name
      onWifiClicked: root.togglePanel("wifi")
      onSoundClicked: root.togglePanel("audio")
      onSettingsClicked: Settings.State.toggle(root.screen.name)
      onCollapseClicked: root.toggleRequested()
    }
  }
}
