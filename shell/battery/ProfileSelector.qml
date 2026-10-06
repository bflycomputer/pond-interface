pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Services.UPower
import ".." as Shell
import "../settings" as Settings

Item {
  id: root

  implicitWidth: 56
  implicitHeight: 143

  readonly property var profiles: [
    { profile: PowerProfile.PowerSaver, name: "Eco", icon: "eco", accent: "#CBE25B" },
    { profile: PowerProfile.Balanced, name: "Balanced", icon: "balanced", accent: "#E99FFF" },
    { profile: PowerProfile.Performance, name: "Performance", icon: "performance", accent: "#FFE51D" }
  ]

  Rectangle {
    anchors.horizontalCenter: parent.horizontalCenter
    width: 16
    height: 5
    topLeftRadius: 2
    topRightRadius: 2
    color: Settings.Style.card
  }

  Rectangle {
    y: 7
    width: root.width
    height: 136
    radius: Settings.Style.radius
    color: Settings.Style.card

    MouseArea { anchors.fill: parent }

    Column {
      anchors.centerIn: parent

      Repeater {
        model: root.profiles

        delegate: Shell.IconButton {
          id: button
          required property var modelData

          readonly property bool selected: PowerProfiles.profile === modelData.profile
          readonly property bool available: modelData.profile !== PowerProfile.Performance
              || PowerProfiles.hasPerformanceProfile
          readonly property bool highlighted: enabled && (hovered || activeFocus)
          readonly property color accent: modelData.accent

          width: 40
          height: 40
          enabled: available
          activeFocusOnTab: true
          accessibleName: modelData.name
          iconWidth: 20
          iconHeight: 20
          animateGlyphOpacity: false
          iconSource: Qt.resolvedUrl("../assets/battery/" + modelData.icon
              + (selected || highlighted ? "-active" : "") + ".svg")
          glyphOpacity: !available ? 0.2 : selected || highlighted ? 1 : 0.5

          Accessible.role: Accessible.RadioButton
          Accessible.name: accessibleName
          Accessible.checkable: true
          Accessible.checked: selected
          Accessible.onPressAction: choose()

          onClicked: choose()
          Keys.onSpacePressed: choose()
          Keys.onReturnPressed: choose()
          Keys.onEnterPressed: choose()

          function choose() {
            if (enabled && available)
              PowerProfiles.profile = modelData.profile;
          }

          Rectangle {
            anchors.fill: parent
            z: -1
            radius: width / 2
            color: button.selected ? Qt.alpha(button.accent, 0.1)
                : button.highlighted ? Settings.Style.hover : "transparent"
          }

          Text {
            id: label
            x: -16 - width
            y: (button.height + metrics.capitalHeight) / 2 - baselineOffset
            text: button.modelData.name
            color: button.accent
            opacity: button.highlighted ? 0.7 : 0
            font.family: Shell.Theme.titleFontFamily
            font.styleName: "Book"
            font.pixelSize: 20
            FontMetrics { id: metrics; font: label.font }
          }
        }
      }
    }
  }
}
