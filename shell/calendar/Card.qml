pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import "Dates.js" as Dates
import ".." as Shell

Shell.PanelBackground {
  id: root
  property date today: clock.date
  property bool followToday: true
  property date browsedMonth: Dates.monthStart(today)
  readonly property date displayedMonth: followToday
      ? Dates.monthStart(today) : browsedMonth
  readonly property bool isCurrentMonth: Dates.sameMonth(displayedMonth, today)
  readonly property var days: Dates.monthDays(displayedMonth)
  readonly property int weekRow: isCurrentMonth
      ? Dates.currentWeekRow(days, today) : -1
  readonly property real cellWidth: (width - 20 - 12) / 7
  readonly property real cellHeight: 36
  readonly property real rowPitch: cellHeight + 2
  readonly property string monthTitle: Qt.locale("en_US").standaloneMonthName(
      displayedMonth.getMonth(), Locale.LongFormat) + ", " + displayedMonth.getFullYear()

  implicitWidth: 264
  implicitHeight: 76 + days.length / 7 * rowPitch - 2 + 10
  Accessible.role: Accessible.Pane
  Accessible.name: monthTitle + " calendar"

  function showMonth(month) {
    browsedMonth = Dates.monthStart(month);
    followToday = Dates.sameMonth(month, today);
  }
  function moveMonth(delta) { showMonth(Dates.shiftMonth(displayedMonth, delta)); }
  function goToday() { followToday = true; }

  SystemClock { id: clock; precision: SystemClock.Minutes }
  FontMetrics { id: metrics; font.family: Shell.Theme.fontFamily; font.pixelSize: 13 }

  // Consume panel clicks so only clicks outside its bounds dismiss it.
  MouseArea {
    anchors.fill: parent
    acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
  }

  Text {
    x: 18
    y: 20 + metrics.capitalHeight - baselineOffset
    text: root.monthTitle
    color: "white"
    font.family: Shell.Theme.fontFamily
    font.pixelSize: 13
    font.weight: Font.Medium
  }

  NavigationButton {
    x: root.width - 84
    y: 13
    visible: !root.isCurrentMonth
    iconSource: Qt.resolvedUrl("../assets/navigation/return.svg")
    iconWidth: 14
    iconHeight: 14
    accessibleName: "Return to today"
    onClicked: root.goToday()
  }
  NavigationButton {
    x: root.width - 60
    y: 13
    iconSource: Qt.resolvedUrl("../assets/navigation/chevron-up.svg")
    accessibleName: "Previous month"
    onClicked: root.moveMonth(-1)
  }
  NavigationButton {
    x: root.width - 36
    y: 13
    iconSource: Qt.resolvedUrl("../assets/navigation/chevron-down.svg")
    accessibleName: "Next month"
    onClicked: root.moveMonth(1)
  }

  Repeater {
    model: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
    delegate: Text {
      required property int index
      required property string modelData
      x: 10 + index * (root.cellWidth + 2)
      y: 55 + metrics.capitalHeight - baselineOffset
      width: root.cellWidth
      text: modelData
      horizontalAlignment: Text.AlignHCenter
      color: "white"
      opacity: 0.5
      font.family: Shell.Theme.fontFamily
      font.pixelSize: 13
    }
  }

  Rectangle {
    x: 10
    y: 76 + root.weekRow * root.rowPitch
    width: root.width - 20
    height: root.cellHeight
    radius: 8
    color: Qt.rgba(1, 1, 1, 0.06)
    visible: root.weekRow >= 0
  }

  Repeater {
    model: root.days
    delegate: Rectangle {
      id: cell
      required property int index
      required property date modelData
      readonly property bool isToday: Dates.sameDay(modelData, root.today)
      readonly property bool inMonth: Dates.sameMonth(modelData, root.displayedMonth)
      x: 10 + index % 7 * (root.cellWidth + 2)
      y: 76 + Math.floor(index / 7) * root.rowPitch
      width: root.cellWidth
      height: root.cellHeight
      radius: 8
      color: isToday && root.isCurrentMonth ? "#D1C9FF" : "transparent"
      Accessible.role: Accessible.StaticText
      Accessible.name: Qt.formatDate(modelData, "dddd, MMMM d, yyyy")
          + (isToday ? ", today" : "")

      MouseArea {
        id: dayHover
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        onContainsMouseChanged: {
          hoverExit.stop();
          if (containsMouse)
            hoverFill.opacity = 1;
          else
            hoverExit.restart();
        }
      }
      Rectangle {
        id: hoverFill

        anchors.fill: parent
        radius: parent.radius
        color: Qt.rgba(1, 1, 1, 0.15)
        opacity: 0
      }
      // Animate only exits; pointer entry stops this and sets opacity directly.
      NumberAnimation {
        id: hoverExit
        target: hoverFill
        property: "opacity"
        to: 0
        duration: 150
        easing.type: Easing.OutCubic
      }

      Text {
        width: parent.width
        y: (cell.height - 10) / 2 + metrics.capitalHeight - baselineOffset
        text: cell.modelData.getDate()
        horizontalAlignment: Text.AlignHCenter
        color: cell.isToday && root.isCurrentMonth ? "#643957" : "white"
        opacity: cell.inMonth ? 1 : 0.3
        font.family: Shell.Theme.fontFamily
        font.pixelSize: 13
      }
    }
  }

  component NavigationButton: Shell.IconButton {
    id: root
    restingOpacity: 1
    iconWidth: 24
    iconHeight: 24
    activeFocusOnTab: visible
    Accessible.role: Accessible.Button
    Accessible.name: accessibleName
    Accessible.onPressAction: clicked()
    Keys.onSpacePressed: clicked()
    Keys.onReturnPressed: clicked()

    Rectangle {
      anchors.fill: parent
      z: -1
      radius: 4
      color: Qt.rgba(1, 1, 1, root.hovered || root.activeFocus ? 0.15 : 0)
    }
  }
}
