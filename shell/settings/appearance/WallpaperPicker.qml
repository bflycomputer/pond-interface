pragma ComponentBehavior: Bound
import QtQuick
import "." as Appearance
import ".." as Settings
import "../.." as Shell

Settings.Modal {
  id: root
  objectName: "wallpaperPicker"
  title: "Wallpaper"
  closeLabel: "Back to appearance"
  closeButtonY: -20
  implicitWidth: 624
  implicitHeight: Math.min(616, availableHeight)
  bodyTop: Appearance.State.error ? 106 : 78
  roundedContent: true
  contentHeight: grid.height + 34
  onBackRequested: Settings.State.back()
  Keys.onEscapePressed: Settings.State.back()

  function focusTile(index) {
    const tile = tiles.itemAt(index);
    if (tile) tile.forceActiveFocus(Qt.TabFocusReason);
  }
  function reveal(tile) {
    const top = tile.y;
    const bottom = top + tile.height + 8;
    if (top < scrollItem.contentY) scrollItem.contentY = top;
    else if (bottom > scrollItem.contentY + scrollItem.height)
      scrollItem.contentY = Math.min(contentHeight - scrollItem.height, bottom - scrollItem.height);
  }

  Grid {
    id: grid
    x: 30; y: 4
    columns: 2; spacing: 12
    enabled: !Appearance.State.busy
    Repeater {
      id: tiles
      model: [{adding: true, title: "Choose an image"}].concat(Appearance.State.wallpapers)
      delegate: WallpaperTile {
        required property var modelData
        required property int index
        objectName: "wallpaperTile" + index
        adding: !!modelData.adding
        dynamic: !!modelData.dynamic
        title: modelData.title || ""
        subtitle: modelData.subtitle || ""
        source: modelData.thumbnail || modelData.url || ""
        selected: dynamic ? Appearance.State.wallpaperMode === "dynamic"
            : !adding && Appearance.State.wallpaperMode === "custom"
                && Appearance.State.wallpaperPath === modelData.path
        onClicked: {
          if (adding) Appearance.State.pickWallpaper();
          else if (dynamic) Appearance.State.selectDynamic();
          else Appearance.State.selectWallpaper(modelData.path);
        }
        onActiveFocusChanged: if (activeFocus) root.reveal(this)
        Keys.onLeftPressed: root.focusTile(index - 1)
        Keys.onRightPressed: root.focusTile(index + 1)
        Keys.onUpPressed: root.focusTile(index - 2)
        Keys.onDownPressed: root.focusTile(index + 2)
      }
    }
  }
  overlay: Text {
    x: 30; y: 58; width: parent.width - 60
    visible: !!Appearance.State.error
    text: Appearance.State.error
    elide: Text.ElideRight
    font.family: Shell.Theme.fontFamily; font.pixelSize: 13; color: "#ffb4ab"
  }
}
