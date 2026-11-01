import QtQuick
import Quickshell
import ".." as Shell
import "../battery" as Battery

Shell.Card {
  id: root

  property real collapseProgress: 0
  property date previewTime: systemClock.date
  signal clicked
  signal batteryClicked
  readonly property bool battery: Battery.State.present
  readonly property bool low: Battery.State.low
  readonly property color batteryColor: Battery.State.charging ? "#CBE25B"
      : low ? Battery.State.lowColor : Shell.Theme.sidebarV3Foreground
  Accessible.role: Accessible.Button
  Accessible.name: "Open calendar"
  Accessible.onPressAction: clicked()

  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    onClicked: root.clicked()
  }

  implicitWidth: Shell.Theme.lerp(Shell.Theme.sidebarCardExpandedWidth,
      Shell.Theme.sidebarCardCollapsedWidth, Shell.Theme.collapseWidth(collapseProgress))
  implicitHeight: Shell.Theme.lerp(battery ? (low ? 115 : 75) : Shell.Theme.sidebarTimeExpandedHeight,
      battery ? 155 : 113, Shell.Theme.collapseHeight(collapseProgress))
  radius: Shell.Theme.lerp(12, Shell.Theme.sidebarCardRadius, Shell.Theme.collapseWidth(collapseProgress))
  color: Shell.Theme.daylight
      ? (cardHovered && !battery ? Shell.Theme.sidebarCardHoverFill : Shell.Theme.sidebarCardFill)
      : classicColor

  readonly property real expandedOpacity:
      collapseProgress < 0.56 ? 1 : 0
  readonly property real collapsedProgress:
      collapseProgress >= 0.56 ? 1 : 0

  SystemClock {
    id: systemClock
    precision: SystemClock.Minutes
  }

  Item {
    id: expandedContent
    width: Shell.Theme.sidebarCardExpandedWidth
    height: root.height
    opacity: root.expandedOpacity
    visible: opacity > 0.001

    Rectangle {
      x: 4
      y: 4
      width: 148
      height: 50
      topLeftRadius: 8
      topRightRadius: 8
      bottomLeftRadius: 2
      bottomRightRadius: 2
      color: Qt.rgba(1, 1, 1, 0.08)
      visible: root.battery
      opacity: timeHover.hovered ? 1 : 0
      HoverHandler { id: timeHover }
    }

    Text {
      id: timeText

      x: 12
      y: 8
      height: 42
      // An unpadded hour leaves room for AM/PM beside every possible time.
      text: Qt.formatTime(root.previewTime, "h:mm AP").split(" ")[0]
      color: Shell.Theme.sidebarV3Foreground
      font.family: "Advent Pro"
      font.weight: Font.Normal
      font.variableAxes: ({ "wdth": 100 })
      font.pixelSize: 39
      font.letterSpacing: -1.17
      verticalAlignment: Text.AlignVCenter
    }

    FontMetrics { id: periodMetrics; font: periodText.font }

    Text {
      id: periodText

      x: timeText.x + Math.ceil(timeText.implicitWidth - timeText.font.letterSpacing) + 4
      y: 35 + periodMetrics.capitalHeight - baselineOffset
      text: Qt.formatTime(root.previewTime, "AP")
      color: Shell.Theme.sidebarV3Foreground
      opacity: 0.7
      font.family: Shell.Theme.fontFamily
      font.weight: Font.Medium
      font.pixelSize: 11
      font.letterSpacing: 0.11
    }

    Rectangle {
      id: dateBox

      x: 104
      y: 9
      width: 40
      height: 40
      radius: 6
      color: "transparent"
      border.width: 1
      border.color: Shell.Theme.daylight ? Shell.Theme.sidebarInnerOutline : Shell.PanelStyle.outline
      antialiasing: true

      FontMetrics { id: dateMetrics; font: weekdayText.font }

      Text {
        id: weekdayText

        x: 1
        y: 9 + dateMetrics.capitalHeight - baselineOffset
        width: parent.width - 2
        text: Qt.formatDateTime(root.previewTime, "ddd")
        color: Shell.Theme.sidebarV3Foreground
        font.family: Shell.Theme.fontFamily
        font.weight: Font.Normal
        font.pixelSize: 13
        horizontalAlignment: Text.AlignHCenter
      }

      Text {
        x: 1
        y: 22 + dateMetrics.capitalHeight - baselineOffset
        width: parent.width - 2
        text: String(root.previewTime.getDate())
        color: Shell.Theme.sidebarV3Foreground
        font.family: Shell.Theme.fontFamily
        font.weight: Font.Normal
        font.pixelSize: 13
        horizontalAlignment: Text.AlignHCenter
      }
    }

    Rectangle {
      x: 4
      y: 54
      width: 148
      height: batteryArea.height
      topLeftRadius: 2
      topRightRadius: 2
      bottomLeftRadius: 8
      bottomRightRadius: 8
      color: root.low ? Qt.alpha(Battery.State.lowColor, 0.08) : Qt.rgba(1, 1, 1, 0.08)
      visible: batteryArea.containsMouse
    }

    Rectangle {
      x: 12
      y: 61
      width: 132
      height: 2
      radius: 1
      visible: root.battery
      color: root.low ? Battery.State.lowColor : Shell.Theme.sidebarV3Foreground
      opacity: 0.2
    }

    Rectangle {
      id: batteryFill
      x: 12
      y: 61
      width: 132 * Battery.State.percentage / 100
      height: 2
      radius: 1
      visible: root.battery
      color: root.batteryColor
      opacity: root.low || Battery.State.charging || batteryArea.containsMouse ? 1 : 0.7
    }

    Rectangle {
      x: Math.max(12, Math.min(144 - width, batteryFill.x + batteryFill.width - width))
      y: 56
      width: badgeText.implicitWidth + 8
      height: 13
      radius: height / 2
      color: root.batteryColor
      visible: batteryArea.containsMouse

      FontMetrics { id: badgeMetrics; font: badgeText.font }

      Text {
        id: badgeText
        x: 4
        y: (parent.height - badgeMetrics.capitalHeight) / 2 + badgeMetrics.capitalHeight - baselineOffset
        text: Battery.State.level + "%"
        color: "#1D1D1D"
        font.family: Shell.Theme.fontFamily
        font.styleName: "Bold"
        font.pixelSize: 11
      }
    }

    Rectangle {
      x: 12
      y: 71
      width: 132
      height: 32
      radius: 4
      visible: root.low
      color: Qt.alpha(Battery.State.lowColor, 0.1)

      FontMetrics { id: bannerMetrics; font: bannerText.font }

      Text {
        id: bannerText
        anchors.horizontalCenter: parent.horizontalCenter
        y: (parent.height - bannerMetrics.capitalHeight) / 2 + bannerMetrics.capitalHeight - baselineOffset
        text: "Battery at " + Battery.State.level + "%"
        color: Battery.State.lowColor
        font.family: Shell.Theme.fontFamily
        font.weight: Font.Medium
        font.pixelSize: 13
      }
    }

    MouseArea {
      id: batteryArea
      x: 4
      y: 54
      width: 148
      height: root.low ? 57 : 17
      visible: root.battery
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: root.batteryClicked()
      Accessible.role: Accessible.Button
      Accessible.name: "Open battery"
      Accessible.description: Battery.State.description
      Accessible.onPressAction: root.batteryClicked()
    }
  }

  Item {
    id: collapsedContent
    width: Shell.Theme.sidebarCardCollapsedWidth
    height: parent.height
    visible: root.collapsedProgress > 0.001

    readonly property real topPadding: 16
    readonly property real lineStep: 13
    readonly property real dateTop: 75
    readonly property color dividerColor: Shell.Theme.daylight
        ? Shell.Theme.sidebarCardOutline : Shell.Theme.sidebarV3Divider
    FontMetrics {
      id: compactMetrics
      font.family: Shell.Theme.plexFontFamily
      font.pixelSize: 13
    }

    Text {
      x: 0
      y: collapsedContent.topPadding + compactMetrics.capitalHeight - baselineOffset
      width: parent.width
      text: Qt.formatTime(root.previewTime, "hh AP").split(" ")[0]
      color: Shell.Theme.sidebarV3Foreground
      opacity: Shell.Theme.ramp(root.collapsedProgress, 0.00, 0.32)
      font.family: Shell.Theme.plexFontFamily
      font.weight: Font.Normal
      font.pixelSize: 13
      horizontalAlignment: Text.AlignHCenter
    }

    Text {
      x: 0
      y: collapsedContent.topPadding + collapsedContent.lineStep + compactMetrics.capitalHeight - baselineOffset
      width: parent.width
      text: Qt.formatTime(root.previewTime, "mm")
      color: Shell.Theme.sidebarV3Foreground
      opacity: Shell.Theme.ramp(root.collapsedProgress, 0.12, 0.44)
      font.family: Shell.Theme.plexFontFamily
      font.weight: Font.Normal
      font.pixelSize: 13
      horizontalAlignment: Text.AlignHCenter
    }

    Text {
      x: 0
      y: collapsedContent.topPadding + 2 * collapsedContent.lineStep + compactMetrics.capitalHeight - baselineOffset
      width: parent.width
      text: Qt.formatTime(root.previewTime, "AP")
      color: Shell.Theme.sidebarV3Foreground
      opacity: 0.3 * Shell.Theme.ramp(root.collapsedProgress, 0.24, 0.56)
      font.family: Shell.Theme.plexFontFamily
      font.weight: Font.Normal
      font.pixelSize: 13
      horizontalAlignment: Text.AlignHCenter
    }

    Rectangle {
      id: compactDivider
      anchors.horizontalCenter: parent.horizontalCenter
      y: 63 - height / 2
      width: 16
      height: 1
      color: collapsedContent.dividerColor
      opacity: Shell.Theme.ramp(root.collapsedProgress, 0.36, 0.68)
    }

    Text {
      x: 0
      y: collapsedContent.dateTop + compactMetrics.capitalHeight - baselineOffset
      width: parent.width
      text: Qt.formatDateTime(root.previewTime, "ddd").slice(0, 2).toUpperCase()
      color: Shell.Theme.sidebarV3Foreground
      opacity: 0.5 * Shell.Theme.ramp(root.collapsedProgress, 0.48, 0.80)
      font.family: Shell.Theme.plexFontFamily
      font.weight: Font.Normal
      font.pixelSize: 13
      horizontalAlignment: Text.AlignHCenter
    }

    Text {
      x: 0
      y: collapsedContent.dateTop + collapsedContent.lineStep + compactMetrics.capitalHeight - baselineOffset
      width: parent.width
      text: Qt.formatDate(root.previewTime, "dd")
      color: Shell.Theme.sidebarV3Foreground
      opacity: Shell.Theme.ramp(root.collapsedProgress, 0.60, 0.92)
      font.family: Shell.Theme.plexFontFamily
      font.weight: Font.Normal
      font.pixelSize: 13
      horizontalAlignment: Text.AlignHCenter
    }

    Rectangle {
      anchors.horizontalCenter: parent.horizontalCenter
      y: 110 - height / 2
      width: 16
      height: 1
      visible: root.battery
      color: collapsedContent.dividerColor
    }

    Rectangle {
      x: 8
      y: 115
      width: 32
      height: 32
      radius: 8
      visible: root.battery
      color: root.low ? Qt.alpha(Battery.State.lowColor, 0.1) : "transparent"

      Battery.Indicator {
        x: 8
        y: 8
        percentage: Battery.State.percentage
        charging: Battery.State.charging
        color: root.low || Battery.State.charging ? root.batteryColor : "white"
      }

      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.batteryClicked()
        Accessible.role: Accessible.Button
        Accessible.name: "Open battery"
        Accessible.description: Battery.State.description
        Accessible.onPressAction: root.batteryClicked()
      }
    }
  }
}
