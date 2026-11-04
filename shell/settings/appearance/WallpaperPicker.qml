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

  property bool viewportReady: false
  property bool prefetchReady: false
  function viewportChanged() {
    prefetchReady = false;
    prefetchDelay.restart();
  }
  Component.onCompleted: Qt.callLater(function() {
    root.viewportReady = true;
    root.viewportChanged();
  })
  Timer {
    id: prefetchDelay
    interval: 120
    onTriggered: root.prefetchReady = true
  }
  Connections {
    target: root.scrollItem
    function onContentYChanged() { root.viewportChanged(); }
    function onHeightChanged() { root.viewportChanged(); }
  }
  Connections {
    target: Appearance.State
    function onWallpapersChanged() { root.viewportChanged(); }
  }

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
        originalPath: modelData.path || ""
        thumbnail: modelData.thumbnail || ""
        // Grid positions are not settled when delegates are created. Derive the
        // row from the index so offscreen delegates never briefly appear visible.
        property real rowTop: grid.y + Math.floor(index / grid.columns) * (implicitHeight + grid.spacing)
        property bool inViewport: root.viewportReady && root.scrollItem.height > 0
            && rowTop + implicitHeight > root.scrollItem.contentY
            && rowTop < root.scrollItem.contentY + root.scrollItem.height
        property bool nearViewport: root.viewportReady && root.prefetchReady && root.scrollItem.height > 0
            && rowTop + implicitHeight > root.scrollItem.contentY - (implicitHeight + grid.spacing)
            && rowTop < root.scrollItem.contentY + root.scrollItem.height + implicitHeight + grid.spacing
        loadingAllowed: inViewport || nearViewport
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
