import QtQuick
import Quickshell
import Quickshell.Wayland
import "audio" as Audio
import "bluetooth" as Bluetooth
import "settings" as Settings
import "wifi" as Wifi
import "calendar" as Calendar
import "media" as Media
import "minimap" as Minimap
import "notifications" as Notifications
import "installs" as Installs
import Pond.Screenshot as Screenshot

PanelWindow {
  id: root
  required property bool expanded
  property string popup: ""
  property real collapseProgress: expanded ? 0 : 1
  signal toggleRequested
  readonly property real cardWidth: Theme.lerp(Theme.sidebarCardExpandedWidth,
      Theme.sidebarCardCollapsedWidth, Theme.collapseWidth(collapseProgress))
  readonly property real notificationCardCenterY: mainStack.y + notificationCard.y + 24

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
    popup = "";
    Notifications.State.closePanel();
    if (wasVisible) {
      pendingPanel = name;
      panelSwitchDelay.restart();
    } else panel.open();
  }

  function togglePopup(name) {
    dismissPanels();
    Notifications.State.closePanel();
    popup = popup === name ? "" : name;
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
      root.popup = "";
      Notifications.State.closePanel();
    }
  }
  Connections {
    target: Notifications.State
    function onPanelOpenChanged() { if (Notifications.State.panelOpen) root.popup = ""; }
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

  // Fullscreen windows. niri draws them above the Top layer and stops sending
  // frame callbacks to the surfaces they cover, so a covered sidebar can't
  // render or even change layer until much later. Instead the cards slide out
  // on the Overlay layer and the window shrinks to a 1px strip on the screen
  // edge, which stays above the fullscreen window and keeps rendering. Holding
  // the pointer on that strip slides the cards back in over the fullscreen
  // window; they also slide back in when fullscreen ends.
  readonly property var activeWorkspace: NiriMsg.workspaces.find(
      w => w.output === root.screen.name && w.isActive) || null
  readonly property var fullscreenNow: {
    if (NiriMsg.overviewOpen || !activeWorkspace || activeWorkspace.activeWindowId == null)
      return false;
    const toplevel = ToplevelManager.activeToplevel;
    // Focus is on a layer surface such as the launcher, or on another output.
    if (!toplevel || !toplevel.screens.some(s => s.name === root.screen.name)) return null;
    return toplevel.fullscreen;
  }
  property bool fullscreen: false
  property bool revealed: false
  readonly property bool revealHeld: panelOpen || popup !== "" || workspacesCard.dragSession.active
      || (Notifications.State.panelOpen && Notifications.State.panelOutputName === screen.name)
      || (Settings.State.opened && Settings.State.outputName === screen.name)
  readonly property bool fullscreenHidden: fullscreen && !revealed
  property real hideProgress: 0
  readonly property real hideOffset: -hideProgress
      * (Theme.sidebarOuterMargin * 2 + Theme.sidebarCardExpandedWidth)
  property bool hideSettled: false
  property bool raised: false

  onFullscreenNowChanged: fullscreenDelay.restart()
  onFullscreenChanged: if (!fullscreen) revealed = false
  onRevealedChanged: if (!revealed && !fullscreen && !showAnimation.running) raised = false
  onFullscreenHiddenChanged: {
    if (fullscreenHidden) {
      dismissPanels();
      popup = "";
      if (Notifications.State.panelOutputName === screen.name) Notifications.State.closePanel();
      showAnimation.stop();
      raised = true;
      hideAnimation.start();
    } else {
      hideAnimation.stop();
      hideSettled = false;
      if (revealed) raised = true;
      showAnimation.start();
    }
  }

  Timer {
    id: fullscreenDelay
    // Switching between fullscreen apps briefly passes focus through other states.
    interval: root.fullscreenNow === false ? 150 : 30
    onTriggered: if (root.fullscreenNow !== null) root.fullscreen = root.fullscreenNow
  }
  NumberAnimation {
    id: hideAnimation
    target: root
    property: "hideProgress"
    to: 1
    duration: 220
    easing.type: Easing.InCubic
    onFinished: root.hideSettled = true
  }
  Motion {
    id: showAnimation
    target: root
    property: "hideProgress"
    to: 0
    onFinished: if (!root.revealed) root.raised = false
  }
  Timer {
    interval: 300
    running: sidebarHover.hovered && root.hideSettled
    onTriggered: root.revealed = true
  }
  Timer {
    interval: 400
    running: root.revealed && !root.revealHeld && !sidebarHover.hovered
    onTriggered: root.revealed = false
  }
  HoverHandler { id: sidebarHover }

  color: "transparent"
  BackgroundEffect.blurRegion: Theme.translucent ? cardBlur : null
  onHeightChanged: cardBlur.changed()
  Region {
    id: cardBlur
    // Region only remaps its items when one of its own properties changes, and
    // moving the stacks doesn't count. This empty rect follows the slide so the
    // card regions are remapped on every step of it.
    x: root.hideOffset
    regions: [timeCard.blurRegion, workspacesCard.blurRegion, mediaCard.blurRegion,
      notificationCard.blurRegion, installsCard.blurRegion, controls.blurRegion,
      wifiPanel.blurRegion, audioPanel.blurRegion, bluetoothPanel.blurRegion]
  }
  // Keep compositor resizes out of the card animation; only the input area shrinks.
  implicitWidth: hideSettled ? 1 : Math.ceil(Math.max(Theme.sidebarOuterMargin + Theme.sidebarCardExpandedWidth + Theme.sidebarFadeWidth,
      wifiPanel.visible ? panelX + wifiPanel.width + 67 : 0,
      audioPanel.visible ? panelX + audioPanel.width + 67 : 0,
      bluetoothPanel.visible ? panelX + bluetoothPanel.width + 67 : 0))
  mask: Region {
    width: root.hideSettled ? 1 : root.panelOpen ? root.implicitWidth : Math.ceil(Theme.sidebarOuterMargin + Math.max(root.cardWidth,
        workspacesCard.width, mediaCard.width, controls.width) + 8)
    height: root.height
    // Let the background receive clicks between the card stacks.
    Region {
      y: Math.ceil(mainStack.y + mainStack.height)
      width: root.width
      height: root.hideSettled ? 0 : Math.max(0, Math.floor(bottomStack.y) - y)
      intersection: Intersection.Subtract
    }
    // Region.item can retain the opening animation's scaled bounds and leave
    // the close button outside the input mask. Track the panel bounds directly.
    Region {
      x: root.activePanel ? root.activePanel.x : 0
      y: root.activePanel ? root.activePanel.y : 0
      width: root.activePanel ? root.activePanel.width : 0
      height: root.activePanel ? root.activePanel.height : 0
    }
  }
  anchors { left: true; top: true; bottom: true }
  WlrLayershell.layer: raised ? WlrLayer.Overlay : WlrLayer.Top
  WlrLayershell.namespace: "pond-sidebar"
  WlrLayershell.keyboardFocus: workspacesCard.dragSession.active
      ? WlrKeyboardFocus.Exclusive : panelOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
  WlrLayershell.exclusionMode: ExclusionMode.Normal
  exclusiveZone: Theme.sidebarOuterMargin + (expanded
      ? Theme.sidebarCardExpandedWidth : Theme.sidebarCardCollapsedWidth)
  Behavior on collapseProgress { Motion {} }

  Column {
    id: mainStack
    x: Theme.sidebarOuterMargin + root.hideOffset
    y: Theme.sidebarOuterMargin
    spacing: Theme.sidebarCardGap

    Calendar.Clock {
      id: timeCard
      width: root.cardWidth
      collapseProgress: root.collapseProgress
      onClicked: root.togglePopup("calendar")
      onBatteryClicked: root.togglePopup("battery")
    }

    Minimap.Map {
      id: workspacesCard
      screen: root.screen
      collapseProgress: root.collapseProgress
      maximumHeight: Math.max(64,
          bottomStack.y - Theme.sidebarCardGap - mainStack.y
          - timeCard.height - mediaCard.height - notificationCard.height - installsCard.height
          - (keyboardFeedback.visible ? keyboardFeedback.height + Theme.sidebarCardGap : 0)
          - Theme.sidebarCardGap * (2 + (mediaCard.visible ? 1 : 0) + (installsCard.visible ? 1 : 0)))
      onFocusRequested: index => NiriMsg.focusWorkspace(index)
      onWindowRequested: windowId => NiriMsg.focusWindow(windowId)
      onAddRequested: workspaceId => NiriMsg.openLauncher(workspaceId)
    }

    Media.Player {
      id: mediaCard
      collapseProgress: root.collapseProgress
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
    }
    KeyboardFeedback {
      id: keyboardFeedback
      screen: root.screen
      collapseProgress: root.collapseProgress
      expandedTopMargin: mainStack.y + keyboardFeedback.y
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
      const point = panel.mapFromItem(null, eventPoint.scenePosition);
      if (!panel.childAt(point.x, point.y))
        root.dismissPanels();
    }
  }

  Wifi.Panel {
    id: wifiPanel
    x: root.panelX + root.hideOffset
    z: 80
    anchors.bottom: parent.bottom
    anchors.bottomMargin: Theme.sidebarOuterMargin
  }

  Audio.Panel {
    id: audioPanel
    x: root.panelX + root.hideOffset
    z: 80
    anchors.bottom: parent.bottom
    anchors.bottomMargin: Theme.sidebarOuterMargin
  }

  Bluetooth.Panel {
    id: bluetoothPanel
    x: root.panelX + root.hideOffset
    z: 80
    anchors.bottom: parent.bottom
    anchors.bottomMargin: Theme.sidebarOuterMargin
  }

  Column {
    id: bottomStack
    onYChanged: cardBlur.changed()
    x: Theme.sidebarOuterMargin + root.hideOffset
    anchors.bottom: parent.bottom
    anchors.bottomMargin: Theme.sidebarOuterMargin
    width: controls.width
    spacing: Theme.sidebarCardGap
    Screenshot.Preview {
      width: root.cardWidth
      outputName: root.screen.name
      collapsed: root.collapseProgress > 0.5
    }
    BrightnessFeedback {
      screen: root.screen
      collapseProgress: root.collapseProgress
      expandedBottomMargin: Theme.sidebarOuterMargin + controls.height + 8
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
