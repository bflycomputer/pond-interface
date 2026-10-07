pragma ComponentBehavior: Bound

import QtQuick
import "." as Settings
import "appearance" as Appearance
import "display" as Display
import "information" as Information
import "manual" as Manual
import "system" as System
import "../battery" as Battery
import Quickshell
import Quickshell.Wayland

PanelWindow {
  id: root

  required property var menuScreen

  property bool presented: false
  property int revealStep: -1
  property var revealRanks: []
  readonly property int cardCount: primaryButtons.length + sessionButtons.length
  property string displayedPage: Settings.State.page || "appearance"

  readonly property bool targetOpen: Settings.State.opened
      && Settings.State.outputName === (menuScreen ? menuScreen.name : "")
  readonly property bool cardsOpen: targetOpen && Settings.State.page === ""
  readonly property bool modalOpen: targetOpen && Settings.State.page !== ""

  readonly property var primaryButtons: [
    {
      slot: 0, x: 0, y: 0, name: "Appearance", page: "appearance",
      source: Qt.resolvedUrl("../assets/settings/appearance.svg"),
      boxWidth: 48, boxHeight: 48, iconWidth: 48, iconHeight: 48
    },
    {
      slot: 1, x: 274, y: 0, name: "Bluetooth", page: "",
      source: Qt.resolvedUrl("../assets/settings/bluetooth.svg"),
      boxWidth: 30, boxHeight: 48, iconWidth: 30, iconHeight: 48
    },
    {
      slot: 2, x: 0, y: 274, name: "System", page: "system",
      source: Qt.resolvedUrl("../assets/settings/system.svg"),
      boxWidth: 48, boxHeight: 48, iconWidth: 42, iconHeight: 36
    },
    {
      slot: 3, x: 274, y: 274, name: "Information", page: "information",
      source: Qt.resolvedUrl("../assets/settings/information.svg"),
      boxWidth: 48, boxHeight: 48, iconWidth: 48, iconHeight: 48
    }
  ]

  readonly property var sessionButtons: [
    {
      slot: 4, y: 0, action: "lock", name: "Lock screen",
      source: Qt.resolvedUrl("../assets/lock.svg"),
      iconWidth: 32, iconHeight: 32,
      hover: "#FFE51D", control: "#632B0F", labelWidth: 170,
      dot: false
    },
    {
      slot: 5, y: 137, action: "suspend", name: "Sleep",
      source: Qt.resolvedUrl("../assets/settings/sleep.svg"),
      iconWidth: 32, iconHeight: 32,
      hover: "#E99FFF", control: "#681D4F", labelWidth: 74,
      dot: false
    },
    {
      slot: 6, y: 274, action: "reboot", name: "Restart",
      source: Qt.resolvedUrl("../assets/settings/restart.svg"),
      iconWidth: 32, iconHeight: 32,
      hover: "#CEF058", control: "#1B322D", labelWidth: 99,
      dot: false
    },
    {
      slot: 7, y: 411, action: "shutdown", name: "Power off",
      source: Qt.resolvedUrl("../assets/settings/power.svg"),
      iconWidth: 32, iconHeight: 32,
      hover: "#FE6146", control: "#632B0F", labelWidth: 127,
      dot: true
    }
  ]

  screen: menuScreen
  visible: presented && !Appearance.State.pickingWallpaper
  color: "transparent"

  anchors {
    left: true
    right: true
    top: true
    bottom: true
  }

  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.namespace: "pond-settings-"
      + (screen ? screen.name : "unknown")
  WlrLayershell.keyboardFocus: root.targetOpen
      ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
  WlrLayershell.exclusionMode: ExclusionMode.Ignore

  mask: Region {
    x: 0
    y: 0
    width: root.presented ? root.width : 0
    height: root.presented ? root.height : 0
  }

  onTargetOpenChanged: {
    if (targetOpen)
      beginOpen();
    else
      beginClose();
  }
  onCardsOpenChanged: if (cardsOpen) beginOpen()
  Connections {
    target: Settings.State
    function onPageChanged() {
      // Retain the outgoing page until its exit transition finishes.
      if (Settings.State.page !== "") root.displayedPage = Settings.State.page;
    }
  }

  Rectangle {
    anchors.fill: parent
    color: Settings.Style.overlay
    opacity: root.targetOpen ? Settings.Style.overlayOpacity : 0

    Behavior on opacity {
      NumberAnimation {
        duration: Settings.Style.closeDuration
        easing.type: Easing.OutCubic
      }
    }
  }

  MouseArea {
    anchors.fill: parent
    enabled: root.targetOpen
    acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
    onClicked: Settings.State.close()
  }

  Item {
    id: composition
    z: 2
    width: 675
    height: 538
    anchors.centerIn: parent
    clip: false
    enabled: root.cardsOpen
    visible: opacity > 0
    opacity: root.cardsOpen ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: Settings.Style.closeDuration; easing.type: Easing.OutCubic } }

    Repeater {
      model: root.primaryButtons

      delegate: CategoryButton {
        required property var modelData

        x: modelData.x
        y: modelData.y
        width: 264
        height: 264
        iconSource: modelData.source
        iconBoxWidth: modelData.boxWidth
        iconBoxHeight: modelData.boxHeight
        iconWidth: modelData.iconWidth
        iconHeight: modelData.iconHeight
        accessibleName: modelData.name
        onClicked: {
          if (modelData.page) Settings.State.openPage(modelData.page);
          else Settings.State.openBluetooth();
        }
        revealed: root.cardsOpen
            && root.revealStep >= root.revealRanks[modelData.slot]
      }
    }

    Repeater {
      model: root.sessionButtons

      delegate: SessionButton {
        required property var modelData

        x: 548
        y: modelData.y
        width: Settings.Style.sessionSize
        height: Settings.Style.sessionSize
        iconSource: modelData.source
        iconWidth: modelData.iconWidth
        iconHeight: modelData.iconHeight
        showStatusDot: modelData.dot
        hoverColor: modelData.hover
        hoverControlColor: modelData.control
        label: modelData.name
        labelWidth: modelData.labelWidth
        accessibleName: modelData.name
        revealed: root.cardsOpen
            && root.revealStep >= root.revealRanks[modelData.slot]
        onClicked: Settings.State.requestSessionAction(modelData.action)
      }
    }
  }

  Battery.ProfileSelector {
    z: 2
    anchors.right: parent.right
    anchors.rightMargin: 10
    anchors.verticalCenter: parent.verticalCenter
    enabled: root.cardsOpen
    visible: opacity > 0
    opacity: root.cardsOpen ? 1 : 0
    Keys.onEscapePressed: Settings.State.close()
    Behavior on opacity {
      NumberAnimation { duration: Settings.Style.closeDuration; easing.type: Easing.OutCubic }
    }
  }

  // Keep navigation, transitions, and outside-click dismissal in the host.
  Loader {
    id: modal
    z: 3
    anchors.centerIn: parent
    active: root.presented && (root.modalOpen || opacity > 0)
    sourceComponent: ({
      information: informationPage, manual: manualPage, display: displayPage, arrange: arrangePage,
      system: systemPage, keyboard: keyboardPage, timezone: timezonePage
    })[root.displayedPage] || appearancePage
    enabled: root.modalOpen
    opacity: root.modalOpen ? 1 : 0
    scale: root.modalOpen ? 1 : 0.96
    Behavior on opacity { NumberAnimation { duration: Settings.Style.closeDuration; easing.type: Easing.OutCubic } }
    Behavior on scale { NumberAnimation { duration: Settings.Style.closeDuration; easing.type: Easing.OutCubic } }
    onLoaded: item.forceActiveFocus()
  }
  Component {
    id: displayPage
    Display.Panel {
      availableHeight: root.height - 80
      scale: Math.min(1, (root.width - 60) / implicitWidth)
    }
  }
  Component {
    id: arrangePage
    Display.Arrange {
      availableHeight: root.height - 80
      scale: Math.min(1, (root.width - 60) / implicitWidth)
    }
  }
  Component {
    id: appearancePage
    Appearance.Panel {
      availableHeight: Math.max(200, root.height - 70)
      scale: Math.min(1, (root.width - 60) / implicitWidth)
    }
  }
  Component {
    id: informationPage
    Information.Panel {
      availableHeight: Math.max(200, root.height - 70)
      scale: Math.min(1, (root.width - 60) / implicitWidth)
    }
  }
  Component {
    id: systemPage
    System.Panel {
      availableHeight: Math.max(200, root.height - 70)
      scale: Math.min(1, (root.width - 60) / implicitWidth)
    }
  }
  Component {
    id: keyboardPage
    System.Picker {
      title: "Keyboard language"; placeholder: "Search languages"; multiple: true
      options: System.State.languages; selected: System.State.selectedLanguages
      onPicked: id => System.State.toggleLanguage(id)
      availableHeight: Math.max(200, root.height - 70)
      scale: Math.min(1, (root.width - 60) / implicitWidth)
    }
  }
  Component {
    id: timezonePage
    System.Picker {
      title: "Timezone"; placeholder: "Search timezone"
      options: System.State.timezones; selected: [System.State.timezone]
      onPicked: id => System.State.setTimezone(id)
      availableHeight: Math.max(200, root.height - 70)
      scale: Math.min(1, (root.width - 60) / implicitWidth)
    }
  }
  Component {
    id: manualPage
    Manual.Panel {
      availableHeight: Math.max(200, root.height - 70)
      scale: Math.min(1, (root.width - 60) / implicitWidth)
    }
  }
  Item {
    focus: root.cardsOpen
    Keys.onEscapePressed: Settings.State.close()
  }

  Timer {
    id: revealTimer
    interval: Settings.Style.staggerInterval
    repeat: true
    onTriggered: {
      if (root.revealStep >= root.cardCount - 1) {
        stop();
        return;
      }
      root.revealStep += 1;
    }
  }

  Timer {
    id: closeCleanup
    interval: Settings.Style.closeDuration
    onTriggered: {
      if (!root.targetOpen)
        root.presented = false;
    }
  }

  function beginOpen() {
    closeCleanup.stop();
    revealTimer.stop();
    revealRanks = shuffledRanks();
    revealStep = -1;
    presented = true;
    Qt.callLater(function() {
      if (!root.targetOpen)
        return;
      root.revealStep = 0;
      revealTimer.restart();
    });
  }

  function beginClose() {
    revealTimer.stop();
    revealStep = -1;
    if (presented)
      closeCleanup.restart();
  }

  function shuffledRanks() {
    const order = Array.from({length: root.cardCount}, (_, index) => index);
    for (let index = order.length - 1; index > 0; --index) {
      const other = Math.floor(Math.random() * (index + 1));
      const held = order[index];
      order[index] = order[other];
      order[other] = held;
    }
    return order;
  }
}
