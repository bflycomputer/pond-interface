import QtQuick
import "audio" as Audio
import "wifi" as Wifi

Card {
  id: root
  property real collapseProgress: 0
  signal collapseClicked
  readonly property real widthProgress: Theme.ramp(collapseProgress, 0, 0.56)
  readonly property real heightProgress: Theme.ramp(collapseProgress, 0.56, 1)
  width: Theme.lerp(156, 48, widthProgress)
  height: Theme.lerp(openExpandedHeight, 168, heightProgress)
  clip: false

  property bool wifiOpen: false
  property bool soundOpen: false
  property bool wifiHoverRetained: false
  property bool keyboardVolumeVisible: false
  // Wi-Fi metrics and the compact sound control share the same staged exit:
  // fade the content, hold the shell, then collapse its height.
  property bool hoverHeightRetained: false
  property string displayedReveal: ""
  readonly property bool wifiContentVisible: displayedReveal === "wifi"
  readonly property bool soundSliderContentVisible: displayedReveal === "sound"
  readonly property string requestedReveal: wifiPresentationRequested ? "wifi"
      : soundSliderRequested ? "sound" : ""
  signal wifiClicked
  signal soundClicked

  property bool wifiButtonHovered: false
  property bool soundButtonHovered: false
  readonly property bool wifiHovered: wifiButtonHovered
      || (wifiHoverRetained && panelHover.hovered)
  // The compact slider belongs only to the sound control. Keep it open while
  // the pointer moves onto the revealed slider, but not merely because the
  // pointer remains somewhere else inside the settings card.
  readonly property bool soundHovered: soundButtonHovered
      || compactSoundSlider.hovered
  readonly property bool wifiPresentationRequested: wifiHovered || wifiOpen
  readonly property bool wifiMetricsVisible: wifiMetrics.visible
  onWifiMetricsVisibleChanged: Wifi.State.setRateConsumer(root, wifiMetricsVisible)
  Component.onCompleted: Wifi.State.setRateConsumer(root, wifiMetricsVisible)
  Component.onDestruction: Wifi.State.setRateConsumer(root, false)
  readonly property bool soundSliderRequested: !soundOpen && !wifiPresentationRequested
      && collapseProgress < 0.5
      && (soundHovered || keyboardVolumeVisible)
  readonly property int openExpandedHeight:
      hoverHeightRetained ? 80 : 48
  // While the expanded card grows for Wi-Fi metrics or the sound slider, use
  // its rendered height rather than the final 80px target. Because this card
  // is bottom-anchored, that keeps the four controls fixed on the baseline
  // instead of moving down once and then riding back up with the card.
  readonly property real expandedControlsY: collapseProgress <= 0.001
      ? height - 44 : openExpandedHeight - 44

  onWifiButtonHoveredChanged: {
    if (wifiButtonHovered) {
      wifiHoverRetained = true;
    }
  }

  onSoundButtonHoveredChanged: {
    if (soundButtonHovered) {
      wifiHoverRetained = false;
    }
  }

  onSoundOpenChanged: {
    if (soundOpen) {
      keyboardVolumeVisible = false;
      keyboardVolumeTimer.stop();
    }
  }

  // Moving controls can transfer hover twice in one event; use the final target.
  onRequestedRevealChanged: Qt.callLater(syncReveal)
  function syncReveal() {
    revealEnter.stop();
    if (requestedReveal === "") {
      displayedReveal = "";
      revealExit.restart();
      return;
    }
    revealExit.stop();
    hoverHeightRetained = true;
    const outgoingOpacity = requestedReveal === "wifi" ? compactSoundSlider.opacity : wifiMetrics.opacity;
    if (outgoingOpacity > 0.001) {
      displayedReveal = "";
      revealEnter.restart();
    } else displayedReveal = requestedReveal;
  }

  HoverHandler {
    id: panelHover
    onHoveredChanged: {
      if (!hovered)
        root.wifiHoverRetained = false;
    }
  }

  Audio.Slider {
    id: compactSoundSlider
    z: 2
    x: 12
    y: 4
    width: 132
    height: 32
    externalValue: Audio.State.outputVolume
    persistentHandle: false
    showInlineValue: false
    interactive: root.soundSliderRequested
    visible: opacity > 0.001
    opacity: root.soundSliderContentVisible ? 1 : 0
    onMoved: Audio.State.setOutputVolume(compactSoundSlider.value)

    Behavior on opacity {
      NumberAnimation {
        duration: root.soundSliderContentVisible
            ? PanelStyle.controlDuration : PanelStyle.hoverExitDuration
        easing.type: Easing.OutCubic
      }
    }
  }

  Behavior on height {
    // Hover expansion needs its short local animation, but the sidebar
    // collapse is already animated by collapseProgress. Letting both animate
    // the same height makes the card shell trail behind the four moving
    // controls during the horizontal-to-vertical transition.
    enabled: root.collapseProgress <= 0.001
    NumberAnimation {
      duration: PanelStyle.controlDuration
      easing.type: Easing.OutCubic
    }
  }

  Row {
    id: wifiMetrics
    anchors.horizontalCenter: parent.horizontalCenter
    y: 12
    height: 19
    spacing: 8
    opacity: (root.wifiContentVisible ? 1 : 0)
        * (1 - Theme.ramp(root.collapseProgress, 0.12, 0.32))
    visible: opacity > 0

    Behavior on opacity {
      NumberAnimation {
        duration: root.wifiContentVisible
            ? PanelStyle.controlDuration : PanelStyle.hoverExitDuration
        easing.type: Easing.OutCubic
      }
    }

    Row {
      height: 19
      spacing: 4
      opacity: 0.6
      Image {
        width: 14
        height: 14
        anchors.verticalCenter: parent.verticalCenter
        source: Qt.resolvedUrl("assets/wifi/upload.svg")
      }
      Text {
        height: 19
        text: Wifi.State.uploadRate
        color: "white"
        font.family: Theme.fontFamily
        font.weight: Font.Medium
        font.pixelSize: 13
        verticalAlignment: Text.AlignVCenter
      }
    }

    Rectangle {
      width: 1
      height: 14
      anchors.verticalCenter: parent.verticalCenter
      color: Theme.sidebarV3Foreground
      opacity: 0.24
    }

    Row {
      height: 19
      spacing: 4
      opacity: 0.6
      Image {
        width: 14
        height: 14
        anchors.verticalCenter: parent.verticalCenter
        source: Qt.resolvedUrl("assets/wifi/download.svg")
      }
      Text {
        height: 19
        text: Wifi.State.downloadRate
        color: "white"
        font.family: Theme.fontFamily
        font.weight: Font.Medium
        font.pixelSize: 13
        verticalAlignment: Text.AlignVCenter
      }
    }
  }

  readonly property var icons: [
      { icon: "wifi.svg", width: 13.9972, height: 10.2141 },
      { icon: "sound.svg", width: 14, height: 14 },
      { icon: "settings.svg", width: 13.6667, height: 11.9167 },
      { icon: "", width: 10.1572, height: 12.3327 }
  ]
  Repeater {
    model: 7
    IconButton {
      id: action
      required property int index
      readonly property bool vertical: index > 3
      readonly property int slot: vertical ? index - 3 : index
      readonly property var modelData: root.icons[slot]
      opacity: slot === 0 ? 1 : vertical
          ? Theme.ramp(root.collapseProgress, 0.62 + (slot - 1) * 0.12, 0.76 + (slot - 1) * 0.12)
          : 1 - Theme.ramp(root.collapseProgress, 0.22, 0.42)
      visible: opacity > 0.001
      x: vertical ? 4 : Theme.lerp([4, 42, 78, 114][slot], 4, root.widthProgress)
      y: vertical ? 4 + slot * 40 : Theme.lerp(root.expandedControlsY, 4, root.widthProgress)
      width: vertical ? 40 : Theme.lerp(slot === 0 || slot === 3 ? 38 : 36, 40, root.widthProgress)
      height: 40
      enabled: slot !== 2 && opacity > 0.5
      onHoveredChanged: {
        if (slot === 0) root.wifiButtonHovered = hovered;
        else if (slot === 1) root.soundButtonHovered = hovered;
      }
      readonly property bool selected: slot === 0 ? root.wifiOpen : slot === 1 && root.soundOpen
      restingOpacity: selected || (slot === 1 && root.keyboardVolumeVisible) ? 1 : 0.6
      iconSource: modelData.icon ? Qt.resolvedUrl("assets/" + modelData.icon) : ""
      iconWidth: modelData.width
      iconHeight: modelData.height
      onClicked: {
        if (slot === 0) root.wifiClicked();
        else if (slot === 1) root.soundClicked();
        else root.collapseClicked();
      }
      Accessible.role: Accessible.Button
      Accessible.name: slot === 0 ? "Wi-Fi" : slot === 1 ? "Sound"
          : root.collapseProgress < 0.5 ? "Collapse sidebar" : "Expand sidebar"
      Accessible.ignored: slot === 2
      Accessible.onPressAction: action.clicked()

      Rectangle {
        anchors.fill: parent
        z: -1
        topLeftRadius: action.slot === 0 ? 12 : 4
        topRightRadius: action.slot === 0 ? Theme.lerp(4, 12, root.collapseProgress)
            : action.slot === 3 ? Theme.lerp(12, 4, root.collapseProgress) : 4
        bottomLeftRadius: action.slot === 0 ? Theme.lerp(12, 4, root.collapseProgress)
            : action.slot === 3 ? Theme.lerp(4, 12, root.collapseProgress) : 4
        bottomRightRadius: action.slot === 3 ? 12 : 4
        color: action.selected ? "#303030" : action.hovered ? "#262626" : Qt.rgba(38/255, 38/255, 38/255, 0)
        Behavior on color { ColorAnimation { duration: 120; easing.type: Easing.OutCubic } }
      }

      Repeater {
        model: action.slot === 3 ? 2 : 0
        Image {
          required property int index
          anchors.centerIn: parent
          anchors.horizontalCenterOffset: -0.1667
          width: 10.1572
          height: 12.3327
          source: "assets/navigation/collapse.svg"
          sourceSize: Qt.size(Math.ceil(width * 2), Math.ceil(height * 2))
          fillMode: Image.PreserveAspectFit
          rotation: index === 0 ? 90 : -90
          readonly property real flipProgress: Theme.ramp(root.collapseProgress, 0.42, 0.58)
          opacity: action.glyphOpacity * (index === 0 ? 1 - flipProgress : flipProgress)
          smooth: true
          antialiasing: true
        }
      }
    }
  }
  Timer {
    id: revealExit
    interval: PanelStyle.hoverCollapseDelay
    onTriggered: if (root.requestedReveal === "") root.hoverHeightRetained = false
  }
  Timer {
    id: revealEnter
    interval: PanelStyle.hoverExitDuration
    onTriggered: root.displayedReveal = root.requestedReveal
  }

  Timer {
    id: keyboardVolumeTimer
    interval: 1200
    onTriggered: root.keyboardVolumeVisible = false
  }

  function showKeyboardVolume() {
    if (soundOpen)
      return;
    keyboardVolumeVisible = true;
    keyboardVolumeTimer.restart();
  }
}
