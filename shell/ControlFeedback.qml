import QtQuick
import Quickshell
import Quickshell.Wayland
import "audio" as Audio

// The one card above the bottom controls. Volume and brightness keys show it
// briefly; hovering the sound or Wi-Fi button shows it while the pointer stays
// on the button or the card. With the sidebar open it sits in the sidebar
// above the controls, and a level card there answers the pointer however it
// appeared; collapsed or under a fullscreen window, key feedback floats at
// the bottom of the screen instead.
Item {
  id: root
  required property var screen
  required property real collapseProgress
  property bool fullscreenCovered: false
  property bool soundOpen: false
  property bool wifiOpen: false
  property bool soundButtonHovered: false
  property bool wifiButtonHovered: false
  signal networkClicked

  // Key feedback: "volume" or "brightness" until the dismiss timer runs out.
  property string transientKind: ""
  property real brightnessValue: 0
  property string brightnessTitle: ""
  property bool fine: false
  // Hover: "volume" or "network", held briefly so the pointer can cross the gap.
  property string hoverKind: ""
  // The card's slider is being dragged.
  property bool pressed: false
  readonly property bool collapsed: collapseProgress >= 0.56
  readonly property bool floating: collapsed || fullscreenCovered
  readonly property string hoverRequest: collapseProgress >= 0.5 || fullscreenCovered ? ""
      : soundButtonHovered && !soundOpen ? "volume"
      : wifiButtonHovered && !wifiOpen ? "network" : ""
  readonly property string kind: transientKind || hoverKind
  // What the card shows. It keeps the last kind while the card goes away, so
  // the content never switches (to the volume level, say) on the way out.
  property string shownKind: ""
  onKindChanged: if (kind !== "") shownKind = kind
  readonly property bool interactive: !floating && shownKind !== "network"
      && (cardHovered || pressed || hoverKind === shownKind)
  readonly property bool cardHovered: inlineHover.hovered
  readonly property int cardHeight: 56
  width: Theme.sidebarCardExpandedWidth
  height: cardHeight + 2 // The sidebar's 6px spacing completes the 8px gap below the card.
  visible: kind !== "" && !floating

  onHoverRequestChanged: {
    if (hoverRequest !== "") {
      hoverExit.stop();
      hoverKind = hoverRequest;
    } else hoverExit.restart();
  }
  onCardHoveredChanged: if (!cardHovered) hoverExit.restart()
  Timer {
    id: hoverExit
    interval: 160
    onTriggered: {
      if (root.hoverRequest !== "" || root.cardHovered || root.pressed) return;
      root.hoverKind = "";
    }
  }

  function showTransient(kind, value, direction, fineStep) {
    transientKind = kind;
    fine = fineStep;
    dismissTimer.restart();
    const low = kind === "brightness" ? 0.01 : 0;
    if (direction > 0 && value >= 0.999 || direction < 0 && value <= low + 0.001)
      Qt.callLater(() => {
        const card = root.floating ? floatingCard.item?.card : inlineCard.item;
        if (card && card.bump) card.bump(direction);
      });
  }

  function focused() {
    return NiriMsg.focusedOutputName === "" || NiriMsg.focusedOutputName === screen.name;
  }

  // A drag ends wherever the pointer is; the card may have lost hover meanwhile.
  function release(heldDown) {
    pressed = heldDown;
    if (shownKind === "brightness") Brightness.hold(screen.name, heldDown);
    if (!heldDown) {
      hoverExit.restart();
      dismissTimer.restart();
    }
  }

  Connections {
    target: Audio.State
    function onKeyboardOutputVolumeChanged(value, direction, fine) {
      if (!root.soundOpen && root.focused()) root.showTransient("volume", value, direction, fine);
    }
    function onOutputDeviceSwitched(name) {
      if (!root.soundOpen && root.focused()) root.showTransient("volume", Audio.State.outputVolume, 0, false);
    }
  }
  Connections {
    target: Brightness
    function onLevelChanged(output, value) {
      if (output === root.screen.name) root.brightnessValue = value;
    }
    function onStepped(output, value, direction, fine) {
      if (output !== root.screen.name) return;
      root.brightnessValue = value;
      root.brightnessTitle = /^(eDP|LVDS|DSI)/.test(output) ? "Built-in display" : output;
      root.showTransient("brightness", value, direction, fine);
    }
  }
  // Stay up while in use or until a slow brightness write has landed.
  Timer {
    id: dismissTimer
    interval: 1200
    onTriggered: {
      if (root.cardHovered || root.pressed || root.transientKind === "brightness" && Brightness.busy)
        restart();
      else root.transientKind = "";
    }
  }

  Component {
    id: levelCard
    LevelCard {
      readonly property bool brightness: root.shownKind === "brightness"
      title: brightness ? root.brightnessTitle : Audio.State.displayName(Audio.State.sink)
      icon: Qt.resolvedUrl(brightness ? "assets/brightness.svg" : "assets/sound.svg")
      value: brightness ? root.brightnessValue : Audio.State.outputVolume
      muted: !brightness && Audio.State.outputMuted
      fine: root.transientKind !== "" && root.fine
      interactive: root.interactive
      onMoved: value => {
        if (brightness) Brightness.set(root.screen.name, value);
        else Audio.State.setOutputVolume(value);
      }
      onHeld: pressed => root.release(pressed)
    }
  }
  Component {
    id: networkCard
    NetworkCard {
      Accessible.onPressAction: root.networkClicked()
    }
  }

  Loader {
    id: inlineCard
    width: parent.width
    height: root.cardHeight
    active: root.visible
    sourceComponent: root.shownKind === "network" ? networkCard : levelCard
    HoverHandler {
      id: inlineHover
      cursorShape: root.shownKind === "network" ? Qt.PointingHandCursor : Qt.ArrowCursor
    }
    // The network card opens the Wi-Fi panel, like the button under it.
    TapHandler {
      enabled: root.shownKind === "network"
      onTapped: root.networkClicked()
    }
  }

  LazyLoader {
    id: floatingCard
    active: root.floating && root.transientKind !== ""
    PanelWindow {
      readonly property alias card: card.item
      screen: root.screen
      color: "transparent"
      implicitWidth: Theme.sidebarCardExpandedWidth + 134
      implicitHeight: 67 + root.cardHeight + 40
      anchors { left: true; bottom: true }
      margins.left: Math.round((screen.width + Theme.sidebarOuterMargin
          + Theme.sidebarCardCollapsedWidth - implicitWidth) / 2)
      WlrLayershell.layer: WlrLayer.Overlay
      WlrLayershell.namespace: "pond-level"
      WlrLayershell.exclusionMode: ExclusionMode.Ignore
      mask: Region {}

      Shadow {
        anchors.fill: card
        cornerRadius: PanelStyle.radius
        shadows: PanelStyle.controlShadows
      }
      Loader {
        id: card
        x: 67
        y: 67
        width: Theme.sidebarCardExpandedWidth
        height: root.cardHeight
        sourceComponent: levelCard
      }
    }
  }
}
