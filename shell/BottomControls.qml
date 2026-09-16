import QtQuick

Card {
  id: root
  property real collapseProgress: 0
  signal collapseClicked
  readonly property real widthProgress: Theme.ramp(collapseProgress, 0, 0.56)
  readonly property real heightProgress: Theme.ramp(collapseProgress, 0.56, 1)
  width: Theme.lerp(156, 48, widthProgress)
  height: Theme.lerp(48, 168, heightProgress)

  readonly property var icons: [
      { icon: "wifi.svg", width: 13.9972, height: 10.2141 },
      { icon: "sound.svg", width: 14, height: 14 },
      { icon: "settings.svg", width: 13.6667, height: 11.9167 },
      { icon: "", width: 10.1572, height: 12.3327 }
  ]
  Repeater {
    model: 7
    IconButton {
      id: action
      required property int index
      readonly property bool vertical: index > 3
      readonly property int slot: vertical ? index - 3 : index
      readonly property var modelData: root.icons[slot]
      opacity: slot === 0 ? 1 : vertical
          ? Theme.ramp(root.collapseProgress, 0.62 + (slot - 1) * 0.12, 0.76 + (slot - 1) * 0.12)
          : 1 - Theme.ramp(root.collapseProgress, 0.22, 0.42)
      visible: opacity > 0.001
      x: vertical ? 4 : Theme.lerp([4, 42, 78, 114][slot], 4, root.widthProgress)
      y: vertical ? 4 + slot * 40 : 4
      width: vertical ? 40 : Theme.lerp(slot === 0 || slot === 3 ? 38 : 36, 40, root.widthProgress)
      height: 40
      enabled: slot === 3 && opacity > 0.5
      iconSource: modelData.icon ? Qt.resolvedUrl("assets/" + modelData.icon) : ""
      iconWidth: modelData.width
      iconHeight: modelData.height
      onClicked: root.collapseClicked()
      Accessible.role: Accessible.Button
      Accessible.name: root.collapseProgress < 0.5 ? "Collapse sidebar" : "Expand sidebar"
      Accessible.ignored: slot !== 3
      Accessible.onPressAction: root.collapseClicked()

      Rectangle {
        anchors.fill: parent
        z: -1
        topLeftRadius: 4
        topRightRadius: Theme.lerp(12, 4, root.collapseProgress)
        bottomLeftRadius: Theme.lerp(4, 12, root.collapseProgress)
        bottomRightRadius: 12
        color: action.hovered ? "#262626" : Qt.rgba(38/255, 38/255, 38/255, 0)
        Behavior on color { ColorAnimation { duration: 120; easing.type: Easing.OutCubic } }
      }

      Repeater {
        model: action.slot === 3 ? 2 : 0
        Image {
          required property int index
          anchors.centerIn: parent
          anchors.horizontalCenterOffset: -0.1667
          width: 10.1572
          height: 12.3327
          source: "assets/navigation/collapse.svg"
          sourceSize: Qt.size(Math.ceil(width * 2), Math.ceil(height * 2))
          fillMode: Image.PreserveAspectFit
          rotation: index === 0 ? 90 : -90
          readonly property real flipProgress: Theme.ramp(root.collapseProgress, 0.42, 0.58)
          opacity: action.glyphOpacity * (index === 0 ? 1 - flipProgress : flipProgress)
          smooth: true
          antialiasing: true
        }
      }
    }
  }
}
