pragma ComponentBehavior: Bound
import QtQuick
import Quickshell.Services.UPower
import "." as Battery
import ".." as Shell

Shell.PanelBackground {
  id: root
  property string hoveredProfile: ""
  readonly property UPowerDevice device: Battery.State.device
  readonly property bool charging: device.state === UPowerDeviceState.Charging
  readonly property string selectedProfile:
      Battery.State.profiles.find(profile => profile.profile === PowerProfiles.profile)?.name ?? ""

  implicitWidth: 280
  implicitHeight: 217
  Accessible.role: Accessible.Pane
  Accessible.name: qsTrId("pond.battery")

  function duration(seconds) {
    const minutes = Math.round(seconds / 60);
    const hours = Math.floor(minutes / 60);
    return hours > 0 ? hours + "h " + minutes % 60 + "m" : minutes + "m";
  }

  MouseArea {
    anchors.fill: parent
    acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
  }

  Label { x: 20; capTop: 20; text: qsTrId("pond.battery"); opacity: 0.7 }

  Image {
    x: status.x - 13
    y: 18
    width: 6
    height: 12
    visible: status.visible
    source: Qt.resolvedUrl("../assets/battery/bolt.svg")
    sourceSize: Qt.size(12, 24)
  }
  Label {
    id: status
    x: 260 - width
    capTop: 20
    visible: Battery.State.charging
    text: root.charging ? qsTrId("pond.charging") : qsTrId("pond.charged")
    color: "#CBE25B"
  }

  Label {
    x: 20
    capTop: 53
    text: Battery.State.level + "%"
    font.family: Shell.Theme.titleFontFamily
    font.styleName: "Regular"
    font.pixelSize: 39
    font.letterSpacing: -1.17
  }

  Item {
    x: 254 - width
    width: Math.max(rate.x + rate.width, remaining.width)
    visible: root.charging || !Battery.State.charging

    Image {
      y: 53
      width: 9
      height: 9
      visible: root.charging && rate.visible
      source: Qt.resolvedUrl("../assets/battery/plus.svg")
      sourceSize: Qt.size(18, 18)
    }
    Label {
      id: rate
      x: root.charging ? 11 : 0
      capTop: 53
      visible: root.device.changeRate !== 0
      text: Math.round(Math.abs(root.device.changeRate)) + "W"
      color: root.charging ? "#CBE25B" : Shell.Theme.sidebarV3Foreground
      opacity: root.charging ? 1 : 0.4
    }
    Label {
      id: remaining
      x: parent.width - width
      capTop: 71
      opacity: 0.7
      text: root.charging
          ? (root.device.timeToFull > 0 ? root.duration(root.device.timeToFull) + " to full" : "")
          : (root.device.timeToEmpty > 0 ? root.duration(root.device.timeToEmpty) + " left" : "")
    }
  }

  Rectangle {
    x: 20
    y: 96
    width: 240
    height: 20
    radius: 6
    color: Qt.rgba(1, 1, 1, 0.1)

    Rectangle {
      width: parent.width * Battery.State.percentage / 100
      height: parent.height
      radius: 6
      color: Shell.Theme.sidebarV3Foreground
      gradient: Battery.State.charging ? chargeGradient : null
    }
  }

  Gradient {
    id: chargeGradient
    orientation: Gradient.Horizontal
    GradientStop { position: 0; color: Qt.rgba(111 / 255, 124 / 255, 50 / 255, 0) }
    GradientStop { position: 0.48134; color: "#CBE25B" }
  }

  Label { x: 20; capTop: 136; text: qsTrId("pond.power_profile"); opacity: 0.7 }
  Label {
    x: 260 - width
    capTop: 136
    text: root.hoveredProfile || root.selectedProfile
    color: "white"
  }

  Repeater {
    model: Battery.State.profiles

    delegate: Battery.PowerProfileButton {
      id: button
      required property int index

      x: 20 + index * 82
      y: 157
      width: 76
      height: 40
      iconSource: Qt.resolvedUrl("../assets/battery/" + modelData.icon + (selected ? "-active" : "") + ".svg")
      glyphOpacity: !available ? 0.2 : selected || highlighted ? 1 : 0.6

      onHighlightedChanged: {
        if (highlighted) root.hoveredProfile = modelData.name;
        else if (root.hoveredProfile === modelData.name) root.hoveredProfile = "";
      }

      Rectangle {
        anchors.fill: parent
        z: -1
        radius: 8
        color: button.selected ? Qt.alpha(button.modelData.accent, 0.1)
            : button.highlighted ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(1, 1, 1, 0.08)
      }
    }
  }

  component Label: Text {
    id: label
    property real capTop
    y: capTop + labelMetrics.capitalHeight - baselineOffset
    color: Shell.Theme.sidebarV3Foreground
    font.family: Shell.Theme.fontFamily
    font.weight: Font.Medium
    font.pixelSize: 13
    FontMetrics { id: labelMetrics; font: label.font }
  }
}
