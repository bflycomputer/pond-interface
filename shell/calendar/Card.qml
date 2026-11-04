pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import "Dates.js" as Dates
import ".." as Shell

Shell.PanelBackground {
  id: root
  fill: Shell.Theme.colors.calendarGradient
  property date today: clock.date
  property bool followToday: true
  property string zoom: "days"
  property date browsedMonth: Dates.monthStart(today)
  readonly property date displayedMonth: followToday
      ? Dates.monthStart(today) : browsedMonth
  readonly property bool isCurrentMonth: Dates.sameMonth(displayedMonth, today)
  readonly property bool showingToday: zoom === "days" && isCurrentMonth
  readonly property var days: Dates.monthDays(displayedMonth)
  readonly property int weekRow: isCurrentMonth
      ? Dates.currentWeekRow(days, today) : -1
  readonly property real cellWidth: (width - 20 - 12) / 7
  readonly property color todayFill: Shell.Theme.colors.todayFill
  readonly property real cellHeight: 36
  readonly property real rowPitch: cellHeight + 2
  readonly property int zoomColumns: 4
  readonly property int zoomRows: zoom === "years" ? 4 : 3
  readonly property real zoomTop: 52
  readonly property real zoomGap: 8
  readonly property real zoomCellWidth: (width - 20 - (zoomColumns - 1) * zoomGap) / zoomColumns
  readonly property real zoomCellHeight: (implicitHeight - zoomTop - 10
      - (zoomRows - 1) * zoomGap) / zoomRows
  readonly property var zoomCells: {
    if (zoom === "months") {
      const months = [];
      for (let i = 0; i < 12; i++)
        months.push(i);
      return months;
    }
    if (zoom === "years")
      return Dates.yearPage(displayedMonth.getFullYear());
    return [];
  }
  readonly property string monthTitle: {
    const year = displayedMonth.getFullYear();
    if (zoom === "years") {
      const start = Dates.decadeStart(year);
      return start + " - " + (start + 9);
    }
    if (zoom === "months")
      return String(year);
    return Qt.locale("en_US").standaloneMonthName(
        displayedMonth.getMonth(), Locale.LongFormat) + ", " + year;
  }
  readonly property string previousLabel: zoom === "years" ? "Previous years"
      : zoom === "months" ? "Previous year" : "Previous month"
  readonly property string nextLabel: zoom === "years" ? "Next years"
      : zoom === "months" ? "Next year" : "Next month"

  implicitWidth: 264
  implicitHeight: 76 + 6 * rowPitch - 2 + 10
  Accessible.role: Accessible.Pane
  Accessible.name: monthTitle + " calendar"

  function showMonth(month) {
    browsedMonth = Dates.monthStart(month);
    followToday = Dates.sameMonth(month, today);
    zoom = "days";
  }
  function moveMonth(delta) { showMonth(Dates.shiftMonth(displayedMonth, delta)); }
  function moveYear(delta) {
    browsedMonth = Dates.shiftMonth(displayedMonth, delta * 12);
    followToday = false;
  }
  function moveDecade(delta) {
    browsedMonth = Dates.shiftMonth(displayedMonth, delta * 120);
    followToday = false;
  }
  function moveZoom(delta) {
    if (zoom === "months") moveYear(delta);
    else if (zoom === "years") moveDecade(delta);
    else moveMonth(delta);
  }
  function zoomHeader() {
    if (zoom === "days") zoom = "months";
    else if (zoom === "months") zoom = "years";
  }
  function zoomOut() {
    if (zoom === "years") {
      zoom = "months";
      return true;
    }
    if (zoom === "months") {
      zoom = "days";
      return true;
    }
    return false;
  }
  function pickMonth(monthIndex) {
    showMonth(new Date(displayedMonth.getFullYear(), monthIndex, 1, 12));
  }
  function pickYear(year) {
    browsedMonth = new Date(year, displayedMonth.getMonth(), 1, 12);
    followToday = false;
    zoom = "months";
  }
  function goToday() {
    followToday = true;
    zoom = "days";
  }

  SystemClock { id: clock; precision: SystemClock.Minutes }
  FontMetrics { id: metrics; font.family: Shell.Theme.fontFamily; font.pixelSize: 13 }

  // Consume panel clicks so only clicks outside its bounds dismiss it.
  MouseArea {
    anchors.fill: parent
    acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
  }

  Text {
    id: titleText
    x: 18
    y: 20 + metrics.capitalHeight - baselineOffset
    text: root.monthTitle
    color: Shell.Theme.colors.text
    font.family: Shell.Theme.fontFamily
    font.pixelSize: 13
    font.weight: Font.Medium
  }
  MouseArea {
    id: titleButton
    x: titleText.x - 8
    y: 8
    width: Math.min(titleText.implicitWidth + 16, root.width - 96 - x)
    height: 28
    enabled: root.zoom !== "years"
    hoverEnabled: enabled
    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
    onClicked: root.zoomHeader()
    Accessible.role: Accessible.Button
    Accessible.name: root.zoom === "days"
        ? "Show months in " + root.displayedMonth.getFullYear()
        : "Show years around " + root.displayedMonth.getFullYear()
    Accessible.onPressAction: root.zoomHeader()

    Rectangle {
      anchors.fill: parent
      z: -1
      radius: 4
      color: Qt.rgba(1, 1, 1, titleButton.containsMouse || titleButton.activeFocus ? 0.15 : 0)
    }
  }

  NavigationButton {
    x: root.width - 84
    y: 13
    visible: !root.showingToday
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
    accessibleName: root.previousLabel
    onClicked: root.moveZoom(-1)
  }
  NavigationButton {
    x: root.width - 36
    y: 13
    iconSource: Qt.resolvedUrl("../assets/navigation/chevron-down.svg")
    accessibleName: root.nextLabel
    onClicked: root.moveZoom(1)
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
      color: Shell.Theme.colors.text
      opacity: 0.5
      font.family: Shell.Theme.fontFamily
      font.pixelSize: 13
      visible: root.zoom === "days"
    }
  }

  Rectangle {
    x: 10
    y: 76 + root.weekRow * root.rowPitch
    width: root.width - 20
    height: root.cellHeight
    radius: 8
    color: Shell.Theme.colors.weekFill
    visible: root.zoom === "days" && root.weekRow >= 0
  }

  Repeater {
    model: root.days
    delegate: Rectangle {
      id: cell
      required property int index
      required property date modelData
      readonly property bool isToday: Dates.sameDay(modelData, root.today)
      readonly property bool inMonth: Dates.sameMonth(modelData, root.displayedMonth)
      visible: root.zoom === "days"
      x: 10 + index % 7 * (root.cellWidth + 2)
      y: 76 + Math.floor(index / 7) * root.rowPitch
      width: root.cellWidth
      height: root.cellHeight
      radius: 8
      color: isToday && root.isCurrentMonth ? root.todayFill : "transparent"
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
        color: cell.isToday && root.isCurrentMonth ? "#643957" : Shell.Theme.colors.text
        opacity: cell.inMonth ? 1 : 0.3
        font.family: Shell.Theme.fontFamily
        font.pixelSize: 13
      }
    }
  }

  Repeater {
    model: root.zoomCells
    delegate: Rectangle {
      id: zoomCell
      required property int index
      required property var modelData
      readonly property bool isTodayCell: root.zoom === "months"
          ? modelData === root.today.getMonth()
              && root.displayedMonth.getFullYear() === root.today.getFullYear()
          : modelData === root.today.getFullYear()
      readonly property bool selected: root.zoom === "months"
          ? modelData === root.displayedMonth.getMonth()
          : modelData === root.displayedMonth.getFullYear()
      readonly property bool inRange: root.zoom === "months"
          || Dates.inDecade(modelData, root.displayedMonth.getFullYear())
      readonly property string label: root.zoom === "months"
          ? Qt.locale("en_US").standaloneMonthName(modelData, Locale.ShortFormat)
          : String(modelData)

      visible: root.zoom !== "days"
      x: 10 + index % root.zoomColumns * (root.zoomCellWidth + root.zoomGap)
      y: root.zoomTop + Math.floor(index / root.zoomColumns) * (root.zoomCellHeight + root.zoomGap)
      width: root.zoomCellWidth
      height: root.zoomCellHeight
      radius: 8
      color: isTodayCell ? root.todayFill : selected ? Shell.Theme.colors.weekFill : "transparent"
      Accessible.role: Accessible.Button
      Accessible.name: label

      MouseArea {
        id: zoomHover
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.zoom === "months" ? root.pickMonth(zoomCell.modelData)
            : root.pickYear(zoomCell.modelData)
        onContainsMouseChanged: {
          zoomHoverExit.stop();
          if (containsMouse)
            zoomHoverFill.opacity = 1;
          else
            zoomHoverExit.restart();
        }
      }
      Rectangle {
        id: zoomHoverFill
        anchors.fill: parent
        radius: parent.radius
        color: Qt.rgba(1, 1, 1, 0.15)
        opacity: 0
      }
      NumberAnimation {
        id: zoomHoverExit
        target: zoomHoverFill
        property: "opacity"
        to: 0
        duration: 150
        easing.type: Easing.OutCubic
      }
      Text {
        anchors.centerIn: parent
        text: zoomCell.label
        color: zoomCell.isTodayCell ? "#643957" : Shell.Theme.colors.text
        opacity: zoomCell.inRange ? 1 : 0.3
        font.family: Shell.Theme.fontFamily
        font.pixelSize: 13
        font.weight: Font.Medium
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
