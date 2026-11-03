import QtQuick
import QtQml.Models
import Quickshell
import "." as Settings
import ".." as Shell

Item {
  id: root

  property url iconSource
  property real iconBoxWidth: 72
  property real iconBoxHeight: 72
  property real iconWidth: iconBoxWidth
  property real iconHeight: iconBoxHeight
  property bool revealed: false
  property string accessibleName: ""
  signal clicked

  readonly property bool hovered: pointer.containsMouse
  readonly property Region blurRegion: Region {
    item: root.revealed && root.opacity > Shell.PanelStyle.blurRevealOpacity ? root : null
    radius: Settings.Style.radius
  }

  implicitWidth: 264
  implicitHeight: 264
  visible: opacity > 0.001
  opacity: revealed ? 1 : 0
  scale: revealed ? 1 : 0.86
  transformOrigin: Item.Center
  onScaleChanged: blurRegion.changed()

  Behavior on opacity {
    NumberAnimation {
      duration: root.revealed ? Settings.Style.revealDuration
                              : Settings.Style.closeDuration
      easing.type: Easing.OutCubic
    }
  }

  Behavior on scale {
    NumberAnimation {
      duration: root.revealed ? Settings.Style.revealDuration
                              : Settings.Style.closeDuration
      easing.type: Easing.OutCubic
    }
  }

  Rectangle {
    id: background
    anchors.fill: parent
    radius: Settings.Style.radius
    color: root.hovered ? Settings.Style.menuCardHover : Settings.Style.menuCard
    gradient: Settings.Style.menuCardHoverGradient ? hoverGradient : null
    clip: true

    property real gradientReveal: root.hovered ? 1 : 0
    Behavior on gradientReveal {
      NumberAnimation {
        duration: Settings.Style.categoryHoverDuration
        easing.type: Easing.InOutCubic
      }
    }
    function blendColor(target: color): color {
      const base = Settings.Style.menuCard;
      const alpha = base.a + (target.a - base.a) * gradientReveal;
      // Blend premultiplied colors so translucency stays continuous.
      const weight = alpha > 0 ? target.a * gradientReveal / alpha : 0;
      return Qt.rgba(base.r + (target.r - base.r) * weight,
                     base.g + (target.g - base.g) * weight,
                     base.b + (target.b - base.b) * weight, alpha);
    }

    Gradient {
      id: hoverGradient
      orientation: Settings.Style.menuCardHoverGradient
          ? Settings.Style.menuCardHoverGradient.orientation : Gradient.Vertical
    }

    Instantiator {
      model: Settings.Style.menuCardHoverGradient
          ? Settings.Style.menuCardHoverGradient.stops : []
      delegate: GradientStop {
        required property var modelData
        position: modelData.position
        color: background.blendColor(modelData.color)
      }
      onObjectAdded: (index, object) => hoverGradient.stops.push(object)
      onObjectRemoved: (index, object) => {
        const stopIndex = hoverGradient.stops.indexOf(object);
        if (stopIndex >= 0) hoverGradient.stops.splice(stopIndex, 1);
      }
    }

    Behavior on color {
      ColorAnimation {
        duration: Settings.Style.categoryHoverDuration
        easing.type: Easing.InOutCubic
      }
    }

    Shell.PanelBorder {
      color: root.hovered ? Settings.Style.menuCardHoverBorder : Settings.Style.menuCardBorder
      radius: parent.radius
      Behavior on color {
        ColorAnimation {
          duration: Settings.Style.categoryHoverDuration
          easing.type: Easing.InOutCubic
        }
      }
    }

    Item {
      width: root.iconBoxWidth
      height: root.iconBoxHeight
      x: 30
      y: 30

      Image {
        anchors.centerIn: parent
        width: root.iconWidth
        height: root.iconHeight
        source: root.iconSource
        sourceSize: Qt.size(Math.ceil(root.iconWidth * 2),
                            Math.ceil(root.iconHeight * 2))
        fillMode: Image.PreserveAspectFit
        smooth: true
        antialiasing: true
      }
    }

    Text {
      x: 30
      y: parent.height - 35 - baselineOffset
      text: root.accessibleName
      color: Shell.Theme.colors.text
      font.family: Shell.Theme.titleFontFamily
      font.weight: Font.Normal
      font.pixelSize: 32
      font.letterSpacing: -0.64
    }
  }

  MouseArea {
    id: pointer
    anchors.fill: parent
    enabled: root.revealed && root.opacity > 0.9
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: root.clicked()
  }
}
