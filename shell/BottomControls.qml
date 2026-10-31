import QtQuick
import Quickshell
import Quickshell.Wayland
import "audio" as Audio
import "wifi" as Wifi

Card {
  id: root
  property real collapseProgress: 0
  signal collapseClicked
  readonly property real widthProgress: Theme.collapseWidth(collapseProgress)
  readonly property real heightProgress: Theme.collapseHeight(collapseProgress)
  width: Theme.lerp(156, 48, widthProgress)
  height: Theme.lerp(48, 168, heightProgress)
  contentClipped: false
  radius: Theme.daylight ? Theme.lerp(12, 16, heightProgress) : Theme.sidebarCardRadius

  property bool wifiOpen: false
  property bool soundOpen: false
  property bool settingsOpen: false
  readonly property var activeToplevel: ToplevelManager.activeToplevel
  readonly property bool fullscreenCovered: activeToplevel !== null && activeToplevel.fullscreen
      && QsWindow.window !== null && activeToplevel.screens.some(s => s.name === QsWindow.window.screen.name)
  signal wifiClicked
  signal settingsClicked
  signal soundClicked

  // Hovering these shows their card above the controls (see ControlFeedback).
  property bool wifiButtonHovered: false
  property bool soundButtonHovered: false

  readonly property var icons: [
      { icon: Wifi.State.statusIcon,
        width: Wifi.State.statusIcon === "wifi.svg" ? 13.9972 : 14,
        height: Wifi.State.statusIcon === "wifi.svg" ? 10.2141 : 14 },
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
      opacity: slot === 0 || (vertical ? root.collapseProgress >= 0.56
          : root.collapseProgress < 0.56) ? 1 : 0
      visible: opacity > 0.001
      x: vertical ? 4 : Theme.lerp([4, 42, 78, 114][slot], 4, root.widthProgress)
      y: vertical ? 4 + slot * 40 : 4
      width: vertical ? 40 : Theme.lerp(slot === 0 || slot === 3 ? 38 : 36, 40, root.widthProgress)
      height: 40
      enabled: opacity > 0.5
      onHoveredChanged: {
        if (slot === 0) root.wifiButtonHovered = hovered;
        else if (slot === 1) root.soundButtonHovered = hovered;
      }
      readonly property bool selected: slot === 0 ? root.wifiOpen : slot === 1 ? root.soundOpen : slot === 2 && root.settingsOpen
      restingOpacity: selected ? 1 : 0.6
      iconSource: modelData.icon ? Qt.resolvedUrl("assets/" + modelData.icon) : ""
      iconWidth: modelData.width
      iconHeight: modelData.height
      onClicked: {
        if (slot === 0) root.wifiClicked();
        else if (slot === 1) root.soundClicked();
        else if (slot === 2) root.settingsClicked();
        else root.collapseClicked();
      }
      Accessible.role: Accessible.Button
      Accessible.name: slot === 0 ? "Wi-Fi" : slot === 1 ? "Sound"
          : slot === 2 ? "Settings" : root.collapseProgress < 0.5 ? "Collapse sidebar" : "Expand sidebar"
      Accessible.onPressAction: action.clicked()

      // Scroll over the sound button to change the volume, like the slider.
      WheelHandler {
        property real pending: 0
        enabled: action.slot === 1
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: event => {
          pending += event.angleDelta.y !== 0 ? event.angleDelta.y : event.angleDelta.x;
          const fine = (event.modifiers & Qt.AltModifier) !== 0;
          while (Math.abs(pending) >= 120) {
            const direction = pending > 0 ? 1 : -1;
            pending -= direction * 120;
            Audio.State.stepOutputVolume(direction, fine);
          }
        }
      }

      Rectangle {
        anchors.fill: parent
        z: -1
        topLeftRadius: action.slot === 0 ? 12 : 4
        topRightRadius: action.slot === 0 ? Theme.lerp(4, 12, root.collapseProgress)
            : action.slot === 3 ? Theme.lerp(12, 4, root.collapseProgress) : 4
        bottomLeftRadius: action.slot === 0 ? Theme.lerp(12, 4, root.collapseProgress)
            : action.slot === 3 ? Theme.lerp(4, 12, root.collapseProgress) : 4
        bottomRightRadius: action.slot === 3 ? 12 : 4
        color: Theme.daylight ? (action.selected || action.hovered ? Theme.sidebarHoverFill : Theme.sidebarClearFill)
            : action.selected ? "#303030" : action.hovered ? "#262626" : Qt.rgba(38/255, 38/255, 38/255, 0)
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
          readonly property real flipProgress: root.collapseProgress >= 0.5 ? 1 : 0
          opacity: action.glyphOpacity * (index === 0 ? 1 - flipProgress : flipProgress)
          smooth: true
          antialiasing: true
        }
      }
    }
  }
}
