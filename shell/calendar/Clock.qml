import QtQuick
import Quickshell
import ".." as Shell

Shell.Card {
  id: root

  property real collapseProgress: 0
  property date previewTime: systemClock.date
  signal clicked
  Accessible.role: Accessible.Button
  Accessible.name: "Open calendar"
  Accessible.onPressAction: clicked()

  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    onClicked: root.clicked()
  }

  implicitWidth: Shell.Theme.lerp(Shell.Theme.sidebarCardExpandedWidth,
      Shell.Theme.sidebarCardCollapsedWidth, collapseProgress)
  implicitHeight: Shell.Theme.lerp(Shell.Theme.sidebarTimeExpandedHeight,
      105, collapseProgress)
  radius: Shell.Theme.lerp(12, Shell.Theme.sidebarCardRadius, collapseProgress)

  readonly property real expandedOpacity:
      1 - Shell.Theme.ramp(collapseProgress, 0.10, 0.45)
  readonly property real collapsedProgress:
      Shell.Theme.ramp(collapseProgress, 0.66, 0.94)

  SystemClock {
    id: systemClock
    precision: SystemClock.Minutes
  }

  Item {
    id: expandedContent
    width: Shell.Theme.sidebarCardExpandedWidth
    height: Shell.Theme.sidebarTimeExpandedHeight
    opacity: root.expandedOpacity
    visible: opacity > 0.001

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
      opacity: 0.5
      font.family: Shell.Theme.fontFamily
      font.weight: Font.Medium
      font.pixelSize: 11
      font.letterSpacing: 0.11
    }

    Rectangle {
      id: dateBox

      x: 106
      y: 9
      width: 40
      height: 40
      radius: 6
      color: "transparent"
      border.width: 1
      border.color: Shell.Theme.daylight ? Shell.Theme.sidebarInnerOutline : Shell.Theme.sidebarV3Border
      antialiasing: true

      FontMetrics { id: dateMetrics; font: weekdayText.font }

      Text {
        id: weekdayText

        x: 1
        y: 9 + dateMetrics.capitalHeight - baselineOffset
        width: parent.width - 2
        text: Qt.formatDateTime(root.previewTime, "ddd")
        color: Shell.Theme.sidebarV3Foreground
        opacity: 0.5
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
        opacity: 0.5
        font.family: Shell.Theme.fontFamily
        font.weight: Font.Normal
        font.pixelSize: 13
        horizontalAlignment: Text.AlignHCenter
      }
    }
  }

  Item {
    id: collapsedContent
    width: Shell.Theme.sidebarCardCollapsedWidth
    height: parent.height
    visible: root.collapsedProgress > 0.001

    readonly property real topPadding: 14
    readonly property real lineStep: 13
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
      x: 16
      y: 58
      width: 16
      height: 1
      color: Shell.Theme.sidebarV3Divider
      opacity: Shell.Theme.ramp(root.collapsedProgress, 0.36, 0.68)
    }

    Text {
      x: 0
      y: 69 + compactMetrics.capitalHeight - baselineOffset
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
      y: 69 + collapsedContent.lineStep + compactMetrics.capitalHeight - baselineOffset
      width: parent.width
      text: Qt.formatDate(root.previewTime, "dd")
      color: Shell.Theme.sidebarV3Foreground
      opacity: Shell.Theme.ramp(root.collapsedProgress, 0.60, 0.92)
      font.family: Shell.Theme.plexFontFamily
      font.weight: Font.Normal
      font.pixelSize: 13
      horizontalAlignment: Text.AlignHCenter
    }
  }
}
