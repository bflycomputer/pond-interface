pragma ComponentBehavior: Bound
import QtQuick
import "." as Appearance
import ".." as Settings
import "../display" as Display
import "../.." as Shell

Settings.Modal {
  id: root
  title: "Appearance"
  contentHeight: fields.y + fields.height + 30
  onBackRequested: Settings.State.back()
  Keys.onEscapePressed: Settings.State.back()

  property string previewTheme: ""
  readonly property var themes: [
    { key: "north", label: "North", x: 247, y: 2, turn: 0, hoverFill: Qt.alpha("#B4C7E8", 0.3),
      hoverGlyph: "#B4C7E8", activeFill: "#B4C7E8", activeGlyph: "#2F465C", labelColor: "#B4C7E8" },
    { key: "daylight", label: "Daylight", x: 149, y: 101, turn: 0, hoverFill: "transparent",
      hoverGlyph: "#F5E4C8", activeFill: "transparent", activeGlyph: "#FFF2DD" },
    { key: "unthemed", label: "Unthemed", x: 247, y: 101, turn: 90, hoverFill: "#4C4C4C",
      hoverGlyph: "white", activeFill: Qt.rgba(1, 1, 1, 0.8), activeGlyph: "#282828" },
    { key: "hazel", label: "Hazel", x: 345, y: 101, turn: 90, hoverFill: Qt.alpha("#D3A95A", 0.3),
      hoverGlyph: "#EBC98B", activeFill: "#EBC98B", activeGlyph: "#3C2E24", labelColor: "#EBC98B" },
    { key: "wisteria", label: "Wisteria", x: 247, y: 199, turn: 45, hoverFill: Qt.alpha("#D1C9FF", 0.3),
      hoverGlyph: "#D1C9FF", activeFill: "#D1C9FF", activeGlyph: "#38224D", labelColor: "#D1C9FF" }
  ]
  function themeLabel(key) { return themes.find(theme => theme.key === key)?.label ?? ""; }

  Item {
    width: root.width; height: 320
    Text {
      x: 60; y: 135; height: 25
      text: "Theme:"; font.family: Shell.Theme.fontFamily; font.pixelSize: 15
      color: Shell.Theme.colors.text; opacity: 0.7; verticalAlignment: Text.AlignVCenter
    }
    Text {
      x: 469; y: 135; height: 25
      text: root.themeLabel(Shell.Theme.name)
      font.family: Shell.Theme.fontFamily; font.pixelSize: 15
      color: root.themes.find(theme => theme.key === Shell.Theme.name)?.labelColor
          ?? Qt.alpha(Shell.Theme.colors.selection, 0.7)
      verticalAlignment: Text.AlignVCenter
    }
    Text {
      x: 469; y: 159; height: 25
      text: root.previewTheme !== Shell.Theme.name ? root.themeLabel(root.previewTheme) : ""
      font.family: Shell.Theme.fontFamily; font.pixelSize: 15
      color: Qt.alpha(Shell.Theme.colors.text, 0.7); verticalAlignment: Text.AlignVCenter
      opacity: text ? 1 : 0
      Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
    }
    Repeater {
      model: root.themes
      delegate: ThemeButton {
        required property var modelData
        x: modelData.x; y: modelData.y
        objectName: "theme" + modelData.label
        theme: modelData
        selected: Shell.Theme.name === modelData.key
        onClicked: Appearance.State.selectTheme(modelData.key)
        onHoveredChanged: {
          if (hovered) root.previewTheme = modelData.key;
          else if (root.previewTheme === modelData.key) root.previewTheme = "";
        }
      }
    }
  }
  Column {
    id: fields
    x: 30; y: 320; width: root.width - 60; spacing: 8
    Accordion {
      objectName: "wallpaperSection"
      width: parent.width; title: "Wallpaper"
      summary: Appearance.State.wallpaperMode === "dynamic" ? "Dynamic" : "Custom"
      navigation: true
      onToggled: Settings.State.openPage("wallpaper")
    }
    Accordion {
      objectName: "brightnessSection"
      width: parent.width; title: "Screen brightness"
      summary: Appearance.State.brightnessAvailable ? Math.round(Appearance.State.brightness * 100) + "%" : "Unavailable"
      enabled: Appearance.State.brightnessAvailable
      expanded: enabled && Appearance.State.expandedSection === "brightness"
      expandedHeight: 109
      onToggled: Appearance.State.toggleSection("brightness")
      Shell.Slider {
        id: brightnessSlider
        objectName: "brightnessSlider"
        x: 0; y: 5; width: parent.width
        externalValue: Appearance.State.brightness
        showInlineValue: false
        onMoved: Appearance.State.setBrightness(brightnessSlider.value)
        onDragStarted: Appearance.State.draggingBrightness = true
        onDragFinished: { Appearance.State.draggingBrightness = false; Appearance.State.flushBrightness(); }
        activeFocusOnTab: true
        Accessible.role: Accessible.Slider
        Accessible.name: "Screen brightness"
        Keys.onLeftPressed: Appearance.State.setBrightness(value - 0.05)
        Keys.onRightPressed: Appearance.State.setBrightness(value + 0.05)
      }
    }
    Accordion {
      objectName: "displaySection"
      width: parent.width; title: "Display"
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
