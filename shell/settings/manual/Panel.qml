import QtQuick
import Quickshell.Widgets
import ".." as Settings
import "../.." as Shell

Settings.Modal {
  id: root
  objectName: "manualPanel"
  title: ""
  implicitWidth: 500
  implicitHeight: Math.min(672, availableHeight)
  bodyTop: 0
  contentHeight: manual.height
  roundedContent: true
  closeButtonY: -17
  closeLabel: "Close manual"
  Accessible.role: Accessible.Dialog
  Accessible.name: "User Manual"
  onBackRequested: Settings.State.back()
  Keys.onEscapePressed: Settings.State.back()
  Keys.onDownPressed: scrollBy(56)
  Keys.onUpPressed: scrollBy(-56)
  Keys.onPressed: event => {
    if (event.key === Qt.Key_PageDown || event.key === Qt.Key_PageUp) {
      scrollBy((scrollItem.height - 40) * (event.key === Qt.Key_PageDown ? 1 : -1));
      event.accepted = true;
    } else if (event.key === Qt.Key_Home) {
      scrollItem.contentY = 0;
      event.accepted = true;
    } else if (event.key === Qt.Key_End) {
      scrollItem.contentY = Math.max(0, contentHeight - scrollItem.height);
      event.accepted = true;
    }
  }

  function scrollBy(distance) {
    scrollItem.contentY = Math.max(0, Math.min(contentHeight - scrollItem.height, scrollItem.contentY + distance));
  }

  Image {
    id: manual
    objectName: "manualContent"
    width: 500; height: 2984
    source: Qt.resolvedUrl("../../assets/manual/manual.svg")
    sourceSize.width: width * Screen.devicePixelRatio
    Item {
      id: note
      objectName: "manualSuperNote"
      x: 30; y: 961; width: 440; height: 66
      HoverHandler { id: noteHover }
      Image {
        anchors.fill: parent
        visible: noteHover.hovered
        source: Qt.resolvedUrl("../../assets/manual/super-note-hover.svg")
        sourceSize.width: width * Screen.devicePixelRatio
      }
    }

    Row {
      x: 180; y: 2894; spacing: 10
      FooterButton { service: "discord" }
      FooterButton { service: "x" }
      FooterButton { service: "mail" }
    }
  }

  // Keep the visualizer outside the rounded, scrolling document clip.
  overlay: Item {
    objectName: "manualSuperKeyTip"
    x: root.width + 10; y: note.y - 33 - root.scrollItem.contentY
    width: 231; height: 144
    visible: noteHover.hovered
    Accessible.role: Accessible.ToolTip
    Accessible.name: "The Super key is between Ctrl and Alt."

    Item {
      anchors { fill: parent; margins: -90; bottomMargin: -180 }
      layer.enabled: true
      layer.format: ShaderEffectSource.RGBA16F
      Shell.Shadow {
        anchors { fill: parent; margins: 90; bottomMargin: 180 }
        cornerRadius: 24
        shadows: Shell.PanelStyle.controlShadows.map(s => Object.assign({}, s, { blur: s.blur * 2.4 }))
      }
    }
    ClippingRectangle {
      anchors.fill: parent
      radius: 24
      color: Settings.Style.card
      Image {
        anchors.fill: parent
        source: Qt.resolvedUrl("../../assets/manual/super-tip.svg")
        sourceSize.width: width * Screen.devicePixelRatio
      }
    }
  }
}
