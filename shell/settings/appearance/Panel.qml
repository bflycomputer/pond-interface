pragma ComponentBehavior: Bound
import QtQuick
import "." as Appearance
import ".." as Settings
import "../.." as Shell

Settings.Modal {
  id: root
  title: "Appearance"
  contentHeight: fields.y + fields.height + 30
  onBackRequested: Settings.State.back()
  Keys.onEscapePressed: Settings.State.back()

  Item {
    width: root.width; height: 241
    Text {
      x: 103; y: 83; height: 25
      text: "Theme:"; font.family: Shell.Theme.fontFamily; font.pixelSize: 15
      color: "#b3b3b3"; verticalAlignment: Text.AlignVCenter
    }
    Text {
      x: 418; y: 83; height: 25
      text: Shell.Theme.daylight ? "Daylight" : "Unthemed"
      font.family: Shell.Theme.fontFamily; font.pixelSize: 15
      color: "#cba6f7"; opacity: 0.7; verticalAlignment: Text.AlignVCenter
    }
    Text {
      x: 418; y: 107; height: 25
      text: upcoming.hovered ? "Coming soon" : daylight.hovered && !daylight.selected ? "Daylight"
          : unthemed.hovered && !unthemed.selected ? "Unthemed" : ""
      font.family: Shell.Theme.fontFamily; font.pixelSize: 15
      color: "#b3b3b3"; verticalAlignment: Text.AlignVCenter
      opacity: text ? 1 : 0
      Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
    }
    ThemeButton {
      id: daylight; objectName: "themeDaylight"
      x: 243; y: 12; themeKey: "daylight"; label: "Daylight"
      selected: Shell.Theme.daylight
      onClicked: Appearance.State.selectTheme("daylight")
    }
    ThemeButton {
      id: unthemed; objectName: "themeUnthemed"
      x: 194; y: 103; themeKey: "unthemed"; label: "Unthemed"
      selected: !Shell.Theme.daylight
      onClicked: Appearance.State.selectTheme("unthemed")
    }
    ThemeButton {
      id: upcoming; objectName: "themeComingSoon"
      x: 294; y: 103; available: false; label: "Coming soon"
    }
  }
  Column {
    id: fields
    x: 30; y: 241; width: root.width - 60; spacing: 8
    Accordion {
      objectName: "wallpaperSection"
      width: parent.width; title: "Wallpaper"
      summary: Appearance.State.wallpaperMode === "dynamic" ? "Dynamic" : "Custom"
      expanded: Appearance.State.expandedSection === "wallpaper"
      expandedHeight: 202
      onToggled: Appearance.State.toggleSection("wallpaper")
      WallpaperOption {
        objectName: "dynamicWallpaper"
        y: 5; width: parent.width; dynamic: true
        selected: Appearance.State.wallpaperMode === "dynamic"
        onClicked: Appearance.State.selectDynamic()
      }
      WallpaperOption {
        objectName: "customWallpaper"
        y: 68; width: parent.width
        selected: Appearance.State.wallpaperMode === "custom"
        onClicked: Appearance.State.pickWallpaper()
      }
    }
    Accordion {
      objectName: "brightnessSection"
      width: parent.width; title: "Screen brightness"
      summary: Appearance.State.brightnessAvailable ? Math.round(Appearance.State.brightness * 100) + "%" : "Unavailable"
      expanded: Appearance.State.expandedSection === "brightness"
      expandedHeight: 109
      onToggled: Appearance.State.toggleSection("brightness")
      Shell.Slider {
        id: brightnessSlider
        objectName: "brightnessSlider"
        x: 0; y: 5; width: parent.width
        externalValue: Appearance.State.brightness
        showInlineValue: false
        interactive: Appearance.State.brightnessAvailable
        opacity: interactive ? 1 : 0.3
        onMoved: Appearance.State.setBrightness(brightnessSlider.value)
        onDragStarted: Appearance.State.draggingBrightness = true
        onDragFinished: { Appearance.State.draggingBrightness = false; Appearance.State.flushBrightness(); }
        activeFocusOnTab: interactive
        Accessible.role: Accessible.Slider
        Accessible.name: "Screen brightness"
        Keys.onLeftPressed: Appearance.State.setBrightness(value - 0.05)
        Keys.onRightPressed: Appearance.State.setBrightness(value + 0.05)
      }
      Text {
        visible: !Appearance.State.brightnessAvailable
        y: 36; width: parent.width
        text: "This display does not expose brightness control."
        color: "#b3b3b3"; font.family: Shell.Theme.fontFamily; font.pixelSize: 11
      }
    }
    Accordion {
      objectName: "displaySection"
      width: parent.width; title: "Display"
      summary: Appearance.State.display.connected ? Appearance.State.display.width + " × "
          + Appearance.State.display.height + " @" + Appearance.State.display.scale + "x" : "Unavailable"
      expanded: Appearance.State.expandedSection === "display"
      expandedHeight: 153
      onToggled: Appearance.State.toggleSection("display")
      Row {
        y: 3; width: parent.width; spacing: 13
        Repeater {
          model: Appearance.State.scales
          delegate: Rectangle {
            id: scaleOption
            required property real modelData
            objectName: "displayScale" + modelData
            readonly property bool selected: Math.abs((Appearance.State.display.scale || 0) - modelData) < 0.01
            width: (parent.width - 39) / 4; height: 80; radius: 8
            color: selected ? "#333333" : scaleHover.hovered || activeFocus ? "#303030" : "transparent"
            border.width: 1
            border.color: selected ? "#cba6f7" : "#3d3d3d"
            enabled: !!Appearance.State.display.connected && !Appearance.State.busy
            activeFocusOnTab: enabled
            Accessible.role: Accessible.Button
            Accessible.name: Math.round(modelData * 100) + "% display scale"
            Accessible.checked: selected
            Accessible.onPressAction: Appearance.State.selectScale(modelData)
            Keys.onReturnPressed: Appearance.State.selectScale(modelData)
            Keys.onSpacePressed: Appearance.State.selectScale(modelData)
            Behavior on color { ColorAnimation { duration: 160; easing.type: Easing.OutCubic } }
            Text {
              anchors.centerIn: parent; text: Math.round(scaleOption.modelData * 100) + "%"
              color: scaleOption.selected ? "#cba6f7" : "#b3b3b3"
              font.family: Shell.Theme.fontFamily; font.pixelSize: 15
            }
            HoverHandler { id: scaleHover; cursorShape: Qt.PointingHandCursor }
            TapHandler { onTapped: Appearance.State.selectScale(scaleOption.modelData) }
          }
        }
      }
    }
    Text {
      width: parent.width
      visible: Appearance.State.error !== ""
      text: Appearance.State.error
      wrapMode: Text.Wrap
      font.family: Shell.Theme.fontFamily; font.pixelSize: 13; color: "#ffb4ab"
    }
  }
}
