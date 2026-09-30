import QtQuick
import ".." as Settings
import QtQuick.Effects

Rectangle {
  id: root
  required property string service
  readonly property string url: service === "discord" ? "https://discord.gg/xJeTd5WJAp"
      : service === "x" ? "https://x.com/bflycomputer" : "mailto:hello@butterfly.so"
  readonly property bool highlighted: hover.hovered || activeFocus
  objectName: "manualContact-" + service
  width: 40; height: 40; radius: 4
  color: highlighted ? "#cba6f7" : "transparent"
  border.width: 1
  border.color: highlighted ? "#cba6f7" : "#4a4a4a"
  activeFocusOnTab: true
  Accessible.role: Accessible.Link
  Accessible.name: service === "mail" ? "Email" : service === "x" ? "X" : "Discord"
  Accessible.onPressAction: root.open()
  Keys.onReturnPressed: root.open()
  Keys.onSpacePressed: root.open()

  function open() {
    Settings.State.close();
    Qt.openUrlExternally(url);
  }

  Image {
    anchors.centerIn: parent
    source: Qt.resolvedUrl("../../assets/manual/" + root.service + ".svg")
    layer.enabled: root.highlighted
    layer.effect: MultiEffect { colorization: 1; colorizationColor: "#1d1d1d" }
  }
  HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
  TapHandler { onTapped: root.open() }
}
