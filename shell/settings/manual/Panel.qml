import QtQuick
import ".." as Settings

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
    width: 500; height: 2811
    source: Qt.resolvedUrl("../../assets/manual/manual.svg")
    sourceSize.width: width * Screen.devicePixelRatio
    Row {
      x: 180; y: 2731; spacing: 10
      FooterButton { service: "discord" }
      FooterButton { service: "x" }
      FooterButton { service: "mail" }
    }
  }
}
