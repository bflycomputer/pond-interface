import QtQuick
import Quickshell.Widgets

ClippingRectangle {
  id: root
  property bool checked: false
  property bool busy: false
  readonly property bool hovered: toggleMouse.containsMouse && root.enabled
  property int animationDuration: 200
  signal toggled(bool checked)
  property real position: checked ? 1 : 0

  implicitWidth: 54
  implicitHeight: 28
  radius: height / 2
  color: root.hovered ? PanelStyle.hover : "transparent"
  border.color: PanelStyle.border
  border.width: 1
  contentInsideBorder: false

  Behavior on position {
    NumberAnimation {
      duration: root.animationDuration
      easing.type: Easing.BezierSpline
      easing.bezierCurve: [0.77, 0, 0.175, 1, 1, 1]
    }
  }

  // Stationary outlines underneath the moving circle.
  Rectangle {
    x: 7.5
    anchors.verticalCenter: parent.verticalCenter
    width: 13
    height: 5
    radius: height / 2
    color: "transparent"
    border.color: Qt.rgba(231 / 255, 231 / 255, 231 / 255, 0.3)
    border.width: 1
  }

  Rectangle {
    x: root.width - 16.5
    anchors.verticalCenter: parent.verticalCenter
    width: 5
    height: 13
    radius: width / 2
    color: "transparent"
    border.color: Qt.rgba(231 / 255, 231 / 255, 231 / 255, 0.3)
    border.width: 1
  }

  Rectangle {
    x: 2 + (root.width - width - 4) * root.position
    anchors.verticalCenter: parent.verticalCenter
    width: 24
    height: 24
    radius: 12
    readonly property real travelDistance: root.width - width - 4
    readonly property real rollingDistance: radius * Math.PI / 2
    readonly property real redSideTravel: travelDistance - rollingDistance
    rotation: Math.max(0, Math.min(rollingDistance,
      travelDistance * root.position - redSideTravel)) / radius * 180 / Math.PI
    antialiasing: true
    color: root.checked ? PanelStyle.enabledSurface : "#613129"
    Behavior on color {
      ColorAnimation {
        duration: root.animationDuration
        easing.type: Easing.BezierSpline
        easing.bezierCurve: [0.77, 0, 0.175, 1, 1, 1]
      }
    }

    Rectangle {
      anchors.centerIn: parent
      width: 12
      height: 4
      radius: height / 2
      antialiasing: true
      color: root.checked ? PanelStyle.enabledMark : "#FB9B89"
      Behavior on color {
        ColorAnimation {
          duration: root.animationDuration
          easing.type: Easing.BezierSpline
          easing.bezierCurve: [0.77, 0, 0.175, 1, 1, 1]
        }
      }
    }
  }

  MouseArea {
    id: toggleMouse
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: if (!root.busy) root.toggled(!root.checked)
  }
}
