pragma ComponentBehavior: Bound
import QtQuick
import "." as Appearance
import ".." as Settings
import "../display" as Display
import "../.." as Shell

Settings.Modal {
  id: root
  title: qsTrId("pond.appearance")
  contentHeight: fields.y + fields.height + 30
  onBackRequested: Settings.State.back()
  Keys.onEscapePressed: Settings.State.back()

  Item {
    width: root.width; height: 241
    Text {
      x: 103; y: 83; height: 25
      text: qsTrId("pond.theme"); font.family: Shell.Theme.fontFamily; font.pixelSize: 15
      color: "#b3b3b3"; verticalAlignment: Text.AlignVCenter
    }
    Text {
      x: 418; y: 83; height: 25
      text: Shell.Theme.daylight ? qsTrId("pond.daylight") : qsTrId("pond.unthemed")
      font.family: Shell.Theme.fontFamily; font.pixelSize: 15
      color: "#cba6f7"; opacity: 0.7; verticalAlignment: Text.AlignVCenter
    }
    Text {
      x: 418; y: 107; height: 25
      text: upcoming.hovered ? qsTrId("pond.coming_soon") : daylight.hovered && !daylight.selected ? qsTrId("pond.daylight")
          : unthemed.hovered && !unthemed.selected ? qsTrId("pond.unthemed") : ""
      font.family: Shell.Theme.fontFamily; font.pixelSize: 15
      color: "#b3b3b3"; verticalAlignment: Text.AlignVCenter
      opacity: text ? 1 : 0
      Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
    }
    ThemeButton {
      id: daylight; objectName: "themeDaylight"
      x: 243; y: 12; themeKey: "daylight"; label: qsTrId("pond.daylight")
      selected: Shell.Theme.daylight
      onClicked: Appearance.State.selectTheme("daylight")
    }
    ThemeButton {
      id: unthemed; objectName: "themeUnthemed"
      x: 194; y: 103; themeKey: "unthemed"; label: qsTrId("pond.unthemed")
      selected: !Shell.Theme.daylight
      onClicked: Appearance.State.selectTheme("unthemed")
    }
    ThemeButton {
      id: upcoming; objectName: "themeComingSoon"
      x: 294; y: 103; available: false; label: qsTrId("pond.coming_soon")
    }
  }
  Column {
    id: fields
    x: 30; y: 241; width: root.width - 60; spacing: 8
    Accordion {
      objectName: "wallpaperSection"
      width: parent.width; title: qsTrId("pond.wallpaper")
      summary: Appearance.State.wallpaperMode === "dynamic" ? qsTrId("pond.dynamic") : qsTrId("pond.custom")
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
      width: parent.width; title: qsTrId("pond.screen_brightness")
      summary: Appearance.State.brightnessAvailable ? Math.round(Appearance.State.brightness * 100) + "%" : qsTrId("pond.unavailable")
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
        Accessible.name: qsTrId("pond.screen_brightness")
        Keys.onLeftPressed: Appearance.State.setBrightness(value - 0.05)
        Keys.onRightPressed: Appearance.State.setBrightness(value + 0.05)
      }
      Text {
        visible: !Appearance.State.brightnessAvailable
        y: 36; width: parent.width
        text: qsTrId("pond.this_display_does_not_expose_brightness_control")
        color: "#b3b3b3"; font.family: Shell.Theme.fontFamily; font.pixelSize: 11
      }
    }
    Accordion {
      objectName: "displaySection"
      width: parent.width; title: qsTrId("pond.display")
      summary: Display.State.summary
      navigation: true
      onToggled: Settings.State.openPage("display")
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
