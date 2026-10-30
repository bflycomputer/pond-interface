pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as Controls
import ".."

Item {
  id: root
  property bool open: false
  property Item anchorItem
  property string currentMode: "wpa-psk"
  readonly property var securityOptions: [
    { label: qsTrId("pond.open_no_password"), mode: "open" },
    { label: qsTrId("pond.enhanced_open_owe"), mode: "owe" },
    { label: qsTrId("pond.wpa_personal_legacy"), mode: "wpa" },
    { label: qsTrId("pond.wpa2_personal"), mode: "wpa2" },
    { label: qsTrId("pond.wpa2_wpa3_personal"), mode: "wpa-psk" },
    { label: qsTrId("pond.wpa3_personal_only"), mode: "sae" },
    { label: qsTrId("pond.wpa2_3_enterprise"), mode: "wpa-eap" },
    { label: qsTrId("pond.wep_key_legacy"), mode: "wep" }
  ]
  property var options: securityOptions
  signal selected(string label, string mode)
  signal dismissed()

  onOpenChanged: if (open) {
    const position = anchorItem.mapToItem(parent, 0, 0);
    x = position.x;
    y = Math.max(16, Math.min(parent.height - height - 16, position.y - height / 2));
    optionList.currentIndex = Math.max(0, options.findIndex(option => option.mode === currentMode));
    optionList.positionViewAtIndex(optionList.currentIndex, ListView.Contain);
    optionList.forceActiveFocus();
  } else {
    Qt.callLater(() => {
      if (!root.open && root.anchorItem?.enabled) root.anchorItem.forceActiveFocus();
    });
  }

  implicitWidth: 276
  implicitHeight: Math.min(272, options.length * 40 + 16)
  visible: root.open || root.opacity > 0.001
  enabled: root.open
  opacity: root.open ? 1 : 0
  scale: root.open ? 1 : 0.96
  transformOrigin: Item.Top

  Behavior on opacity {
    NumberAnimation {
      duration: 100
      easing.type: Easing.OutCubic
    }
  }
  Behavior on scale {
    NumberAnimation {
      duration: 100
      easing.type: Easing.OutCubic
    }
  }

  Shadow {
    anchors.fill: parent
    cornerRadius: 16
    shadows: PanelStyle.controlShadows
  }

  Rectangle {
    anchors.fill: parent
    radius: 16
    color: PanelStyle.surface
    border.color: PanelStyle.border
    border.width: 0.5
    clip: true

    ListView {
      id: optionList
      clip: true
      boundsBehavior: Flickable.StopAtBounds
      ScrollWheel { view: optionList }
      x: 8
      y: 8
      width: 259
      height: root.implicitHeight - 16
      model: root.options
      keyNavigationEnabled: true
      onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)
      Keys.onEscapePressed: root.dismissed()
      Keys.onReturnPressed: root.selected(root.options[currentIndex].label, root.options[currentIndex].mode)
      Keys.onEnterPressed: root.selected(root.options[currentIndex].label, root.options[currentIndex].mode)
      Keys.onSpacePressed: root.selected(root.options[currentIndex].label, root.options[currentIndex].mode)
      Controls.ScrollBar.vertical: Controls.ScrollBar {
        width: 2
        padding: 0
        policy: size < 1 ? Controls.ScrollBar.AlwaysOn : Controls.ScrollBar.AlwaysOff
        contentItem: Rectangle { radius: 2; color: Qt.rgba(1, 1, 1, 0.2) }
        background: null
      }
      delegate: Rectangle {
        id: optionRow
        required property var modelData
        required property int index
        width: optionList.width
        height: 40
        radius: 12
        color: modelData.mode === root.currentMode || rowHover.hovered
            || (optionList.activeFocus && index === optionList.currentIndex)
            ? PanelStyle.hover : "transparent"

        Text {
          x: 12
          anchors.verticalCenter: parent.verticalCenter
          text: optionRow.modelData.label
          color: "white"
          font.family: Theme.fontFamily
          font.weight: Font.Medium
          font.pixelSize: 13
        }
        HoverHandler { id: rowHover; cursorShape: Qt.PointingHandCursor }
        TapHandler {
          onTapped: root.selected(optionRow.modelData.label,
                                  optionRow.modelData.mode)
        }
      }
    }
  }
}
