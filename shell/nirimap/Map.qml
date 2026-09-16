pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import "." as Nirimap
import ".." as Shell

Shell.Card {
  id: root

  property var screen: null
  property real collapseProgress: 0
  property real maximumHeight: 10000
  signal focusRequested(int workspaceIndex)
  signal windowRequested(var windowId)

  readonly property real expandedOpacity:
      1 - Shell.Theme.ramp(collapseProgress, 0.22, 0.58)
  readonly property real collapsedOpacity:
      Shell.Theme.ramp(collapseProgress, 0.68, 0.92)
  readonly property int expandedVisibleRowCount: expandedColumn.height > 0
      ? Math.round((expandedColumn.height + Shell.Theme.workspaceControlGap)
                   / Shell.Theme.workspaceControlPitch)
      : 0
  readonly property int expandedRenderedRowCount: Math.max(
      Shell.Theme.workspaceGridMinimumRows, expandedVisibleRowCount)
  readonly property real expandedNaturalHeight:
      expandedVisibleRowCount <= Shell.Theme.workspaceGridMinimumRows
      ? Shell.Theme.workspaceGridMinimumHeight
      : Shell.Theme.workspaceContentPadding * 2
        + expandedVisibleRowCount * Shell.Theme.workspaceControlSize
        + (expandedVisibleRowCount - 1) * Shell.Theme.workspaceControlGap
  readonly property real collapsedNaturalHeight: collapsedColumn.height
  readonly property real naturalHeight: Shell.Theme.lerp(
      expandedNaturalHeight, collapsedNaturalHeight,
      Shell.Theme.ramp(collapseProgress, 0.18, 0.82))
  readonly property bool workspaceNumbersRevealed: expandedLayer.enabled
      && expandedComponentHover.hovered
  width: {
    if (collapseProgress < 0.38)
      return Shell.Theme.lerp(Shell.Theme.sidebarCardExpandedWidth, 108,
                        Shell.Theme.ramp(collapseProgress, 0.0, 0.38));
    return Shell.Theme.lerp(108, Shell.Theme.sidebarCardCollapsedWidth,
                      Shell.Theme.ramp(collapseProgress, 0.64, 1.0));
  }
  height: Math.min(maximumHeight, naturalHeight)
  // The number hit target reaches ten pixels outside the expanded card. The
  // panel gutter contains it; clipping returns once the compact layer takes
  // over so its top and bottom rows retain the card radius.
  clip: collapseProgress >= 0.55

  Item {
    id: expandedLayer
    x: -10
    width: root.width - x
    height: root.height
    clip: true
    opacity: root.expandedOpacity
    visible: opacity > 0.001
    enabled: root.collapseProgress < 0.55

    HoverHandler {
      id: expandedComponentHover
      enabled: expandedLayer.enabled
    }

    Column {
      id: expandedColumn
      // Own the complete screen-edge rail as part of every row. This keeps
      // pointer delivery inside the delegate instead of depending on an
      // out-of-bounds child to receive the grab.
      x: 0
      y: Shell.Theme.workspaceContentPadding
      width: expandedLayer.width
      spacing: Shell.Theme.workspaceControlGap

      Repeater {
        model: Shell.NiriMsg.workspaceRows

        delegate: Item {
          id: expandedWorkspace

          required property int index
          required property var model

          readonly property bool matchesOutput: expandedWorkspace.model.outputName === ""
              || !root.screen
              || expandedWorkspace.model.outputName === root.screen.name
          readonly property var windowItems: {
            try {
              return JSON.parse(expandedWorkspace.model.windowsJson || "[]");
            } catch (e) {
              return [];
            }
          }
          readonly property int windowStart: Math.min(
              Math.max(0, Number(expandedWorkspace.model.carouselStart) || 0),
              Math.max(0, windowItems.length - Shell.Theme.workspaceGridColumns))
          readonly property int carouselSlotCount: Math.max(
              Shell.Theme.workspaceGridColumns, windowItems.length + 1)
          readonly property int workspaceNumber:
              Number(expandedWorkspace.model.sidebarWorkspaceNumber) || 0
          visible: matchesOutput
          width: expandedColumn.width
          height: matchesOutput ? Shell.Theme.workspaceControlSize : 0
          Rectangle {
            x: Shell.Theme.workspaceActiveIndicatorInset - expandedLayer.x
            y: -Shell.Theme.workspaceControlGap / 2
            width: root.width - Shell.Theme.workspaceActiveIndicatorInset * 2
            height: parent.height + Shell.Theme.workspaceControlGap
            radius: 12
            color: expandedWorkspace.model.isActive
                ? Shell.Theme.workspaceActiveIndicatorColor
                : Qt.rgba(Shell.Theme.workspaceActiveIndicatorColor.r,
                          Shell.Theme.workspaceActiveIndicatorColor.g,
                          Shell.Theme.workspaceActiveIndicatorColor.b, 0)

            Behavior on color {
              ColorAnimation {
                duration: Shell.Theme.sidebarWorkspaceSwitchDuration
                easing.type: Easing.OutCubic
              }
            }
          }

          MouseArea {
            x: -expandedLayer.x
            width: Shell.Theme.sidebarCardExpandedWidth
            height: parent.height
            acceptedButtons: Qt.LeftButton
            cursorShape: Qt.PointingHandCursor
            onClicked: root.focusRequested(
                expandedWorkspace.model.workspaceIndex)
          }

          Item {
            x: Shell.Theme.workspaceContentPadding - expandedLayer.x
            width: Shell.Theme.workspaceGridColumns * Shell.Theme.workspaceControlSize
                + (Shell.Theme.workspaceGridColumns - 1)
                  * Shell.Theme.workspaceControlGap
            height: parent.height
            clip: true

            Item {
              x: -expandedWorkspace.windowStart
                  * Shell.Theme.workspaceControlPitch
              width: expandedWorkspace.carouselSlotCount
                  * Shell.Theme.workspaceControlSize
                  + (expandedWorkspace.carouselSlotCount - 1)
                    * Shell.Theme.workspaceControlGap
              height: parent.height

              Behavior on x { Shell.Motion { duration: 220 } }

              Repeater {
                // Keep a real slot for every window so the row can slide as
                // Niri's horizontal viewport advances.
                model: expandedWorkspace.carouselSlotCount

                delegate: Item {
                  id: workspaceSlot

                  required property int index

                  readonly property bool hasWindow:
                      index < expandedWorkspace.windowItems.length
                  readonly property var windowData: hasWindow
                      ? expandedWorkspace.windowItems[index] : ({})
                  readonly property bool emptyWorkspaceActive: index === 0
                      && expandedWorkspace.windowItems.length === 0
                      && expandedWorkspace.model.isActive

                  x: index * Shell.Theme.workspaceControlPitch
                  width: Shell.Theme.workspaceControlSize
                  height: Shell.Theme.workspaceControlSize

                  Rectangle {
                    anchors.fill: parent
                    visible: workspaceSlot.emptyWorkspaceActive
                    radius: width / 2
                    color: Shell.Theme.workspaceLauncherActive
                    border.color: Shell.Theme.sidebarV3Border
                    border.width: Shell.Theme.sidebarStrokeWidth
                    antialiasing: true
                  }

                  Rectangle {
                    anchors.centerIn: parent
                    visible: !workspaceSlot.hasWindow && !workspaceSlot.emptyWorkspaceActive
                    width: Shell.Theme.workspacePlaceholderDotSize
                    height: Shell.Theme.workspacePlaceholderDotSize
                    radius: width / 2
                    color: Shell.Theme.sidebarInnerOutline
                  }

                  Nirimap.WindowIcon {
                    anchors.fill: parent
                    visible: workspaceSlot.hasWindow
                    controlSize: Shell.Theme.workspaceControlSize
                    windowData: workspaceSlot.windowData
                    onActivated: windowId => root.windowRequested(windowId)
                  }
                }
              }
            }
          }

          Item {
            anchors.verticalCenter: parent.verticalCenter
            z: 30
            width: 20
            height: Shell.Theme.workspaceControlPitch
            visible: root.workspaceNumbersRevealed && expandedWorkspace.workspaceNumber > 0
            Rectangle {
              x: 3
              anchors.verticalCenter: parent.verticalCenter
              width: 14
              height: 20
              radius: 10
              color: numberPointer.containsMouse || numberPointer.pressed
                  ? Shell.Theme.sidebarV3Control : Shell.Theme.sidebarV3WorkspaceActive
              antialiasing: true
              Behavior on color { ColorAnimation { duration: 120; easing.type: Easing.OutCubic } }
              Text {
                anchors.fill: parent
                text: expandedWorkspace.workspaceNumber
                color: Shell.Theme.sidebarV3Foreground
                font.family: Shell.Theme.plexFontFamily
                font.weight: Font.Medium
                font.pixelSize: 11
                font.letterSpacing: 0.11
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
              }
            }
            MouseArea {
              id: numberPointer
              anchors.fill: parent
              hoverEnabled: true
              preventStealing: true
              cursorShape: Qt.PointingHandCursor
              onClicked: root.focusRequested(expandedWorkspace.model.workspaceIndex)
            }
          }
        }
      }
    }

    Column {
      x: Shell.Theme.workspaceContentPadding - expandedLayer.x
      y: Shell.Theme.workspaceContentPadding
          + root.expandedVisibleRowCount * Shell.Theme.workspaceControlPitch
      spacing: Shell.Theme.workspaceControlGap

      Repeater {
        model: Math.max(0, root.expandedRenderedRowCount
                        - root.expandedVisibleRowCount)

        delegate: Row {
          required property int index
          spacing: Shell.Theme.workspaceControlGap

          Repeater {
            model: Shell.Theme.workspaceGridColumns

            delegate: Item {
              required property int index
              width: Shell.Theme.workspaceControlSize
              height: Shell.Theme.workspaceControlSize

              Rectangle {
                anchors.centerIn: parent
                width: Shell.Theme.workspacePlaceholderDotSize
                height: Shell.Theme.workspacePlaceholderDotSize
                radius: width / 2
                color: Shell.Theme.sidebarInnerOutline
              }
            }
          }
        }
      }
    }
  }

  Item {
    id: collapsedLayer
    width: Shell.Theme.sidebarCardCollapsedWidth
    height: collapsedColumn.height
    opacity: root.collapsedOpacity
    visible: opacity > 0.001
    enabled: root.collapseProgress > 0.68

    Column {
      id: collapsedColumn
      width: Shell.Theme.sidebarCardCollapsedWidth

      Repeater {
        model: Shell.NiriMsg.workspaceRows

        delegate: Item {
          id: collapsedWorkspace

          required property var model

          readonly property bool matchesOutput: collapsedWorkspace.model.outputName === ""
              || !root.screen
              || collapsedWorkspace.model.outputName === root.screen.name
          readonly property bool active: !!collapsedWorkspace.model.isActive
          readonly property int workspaceNumber:
              Number(collapsedWorkspace.model.sidebarWorkspaceNumber) || 0
          readonly property int displayNumber: workspaceNumber > 0
              ? workspaceNumber
              : (Number(collapsedWorkspace.model.sidebarRowOrdinal) || 0) + 1
          readonly property var windowItems: {
            try {
              return JSON.parse(collapsedWorkspace.model.windowsJson || "[]");
            } catch (e) {
              return [];
            }
          }
          readonly property int activeHeight:
              Shell.Theme.workspaceCollapsedHeaderHeight
              + windowItems.length * Shell.Theme.workspaceCollapsedControlPitch
              - (windowItems.length > 0 ? Shell.Theme.workspaceCollapsedControlGap : 0)
              + 13

          visible: matchesOutput
          width: Shell.Theme.sidebarCardCollapsedWidth
          height: !matchesOutput ? 0
              : (active ? Math.max(42, activeHeight)
                        : 41)

          Behavior on height {
            NumberAnimation {
              duration: Shell.Theme.sidebarWorkspaceSwitchDuration
              easing.type: Easing.OutCubic
            }
          }

          Rectangle {
            x: 2
            y: collapsedWorkspace.active ? 2 : 3
            width: parent.width - 4
            height: Math.max(0, parent.height - (collapsedWorkspace.active ? 7 : 8))
            radius: 13
            color: collapsedWorkspace.active || collapsedRowPointer.containsMouse
                ? Shell.Theme.workspaceActiveIndicatorColor
                : Qt.rgba(Shell.Theme.workspaceActiveIndicatorColor.r,
                          Shell.Theme.workspaceActiveIndicatorColor.g,
                          Shell.Theme.workspaceActiveIndicatorColor.b, 0)

            Behavior on color {
              ColorAnimation {
                duration: Shell.Theme.sidebarWorkspaceSwitchDuration
                easing.type: Easing.OutCubic
              }
            }
          }

          MouseArea {
            id: collapsedRowPointer
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.focusRequested(
                collapsedWorkspace.model.workspaceIndex)
          }

          Text {
            x: 0
            y: collapsedWorkspace.active ? 8 : 4
            width: Shell.Theme.sidebarCardCollapsedWidth
            height: 19
            text: collapsedWorkspace.displayNumber < 10
                ? "0" + collapsedWorkspace.displayNumber
                : String(collapsedWorkspace.displayNumber)
            color: Shell.Theme.sidebarV3Foreground
            opacity: collapsedWorkspace.active
                ? 1.0 : 0.5
            font.family: Shell.Theme.plexFontFamily
            font.weight: Font.Normal
            font.pixelSize: 13
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter

            Behavior on opacity {
              NumberAnimation {
                duration: Shell.Theme.sidebarWorkspaceSwitchDuration
                easing.type: Easing.OutCubic
              }
            }
          }

          Column {
            visible: collapsedWorkspace.active
            x: 8
            y: Shell.Theme.workspaceCollapsedHeaderHeight
            spacing: Shell.Theme.workspaceCollapsedControlGap

            Repeater {
              // Keep delegates alive when focus, title or activity changes.
              // An array model destroys them on every new JSON snapshot.
              model: collapsedWorkspace.windowItems.length

              delegate: Nirimap.WindowIcon {
                required property int index
                controlSize: Shell.Theme.workspaceCollapsedControlSize
                windowData: collapsedWorkspace.windowItems[index] || ({})
                onActivated: windowId => root.windowRequested(windowId)
              }
            }
          }

          Row {
            visible: !collapsedWorkspace.active
                && collapsedWorkspace.windowItems.length > 0
            y: 26
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 2

            Repeater {
              model: Math.min(4, collapsedWorkspace.windowItems.length)

              delegate: Rectangle {
                id: appDot
                required property int index
                readonly property string imageFile: Quickshell.env("XDG_RUNTIME_DIR")
                    + "/pond-icon-" + Quickshell.processId + "-" + Qt.md5(String(appDot)) + ".png"
                width: 4
                height: 4
                radius: 2
                antialiasing: true
                color: iconColor.colors[0] ?? "white"

                // ColorQuantizer needs a file; theme icons use an image-provider URL.
                Image {
                  id: colorSource
                  width: 32
                  height: 32
                  visible: false
                  asynchronous: true
                  source: Quickshell.iconPath(collapsedWorkspace.windowItems[appDot.index].iconName,
                      "application-x-executable")
                  readonly property bool ready: status === Image.Ready && Boolean(Window.window?.visible)
                  onReadyChanged: if (ready) Qt.callLater(capture)
                  onSourceChanged: {
                    iconColor.source = "";
                    if (ready) Qt.callLater(capture);
                  }
                  function capture() {
                    if (!ready)
                      return;
                    const requested = source.toString();
                    grabToImage(result => {
                      if (source.toString() === requested && result.saveToFile(appDot.imageFile))
                        iconColor.source = "file://" + appDot.imageFile;
                    });
                  }
                }

                ColorQuantizer {
                  id: iconColor
                  depth: 0
                  rescaleSize: 32
                }
                Component.onDestruction: {
                  colorSource.source = "";
                  Quickshell.execDetached(["rm", "-f", imageFile]);
                }
              }
            }
          }

          Rectangle {
            x: 16
            anchors.bottom: parent.bottom
            width: 16
            height: 1
            color: Shell.Theme.sidebarV3Divider
            opacity: 0.8
          }
        }
      }

      Item {
        width: Shell.Theme.sidebarCardCollapsedWidth
        height: 3
      }
    }
  }
}
