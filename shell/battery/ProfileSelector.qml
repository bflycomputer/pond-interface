pragma ComponentBehavior: Bound

import QtQuick
import "." as Battery
import ".." as Shell
import "../settings" as Settings

Item {
  id: root

  implicitWidth: 56
  implicitHeight: 143

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
        model: Battery.State.profiles

        delegate: Battery.PowerProfileButton {
          id: button
          readonly property color accent: modelData.accent

          width: 40
          height: 40
          iconSource: Qt.resolvedUrl("../assets/battery/" + modelData.icon
              + (selected || highlighted ? "-active" : "") + ".svg")
          glyphOpacity: !available ? 0.2 : selected || highlighted ? 1 : 0.5

          Rectangle {
            anchors.fill: parent
            z: -1
            radius: width / 2
            color: button.selected ? Qt.alpha(button.accent, 0.1)
                : button.highlighted ? Shell.PanelStyle.rowHover : "transparent"
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
