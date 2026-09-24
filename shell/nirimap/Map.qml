pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes
import Quickshell
import "." as Nirimap
import ".." as Shell

Shell.Card {
  id: root

  property var screen: null
  property real collapseProgress: 0
  readonly property real widthProgress: Shell.Theme.collapseWidth(collapseProgress)
  readonly property real heightProgress: Shell.Theme.collapseHeight(collapseProgress)
  property real maximumHeight: 10000
  readonly property alias dragSession: dragSession
  signal focusRequested(int workspaceIndex)
  signal windowRequested(var windowId)
  signal addRequested(var workspaceId)

  readonly property real expandedOpacity:
      collapseProgress < 0.56 ? 1 : 0
  readonly property real collapsedOpacity:
      collapseProgress >= 0.56 ? 1 : 0
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
  readonly property real collapsedNaturalHeight: collapsedColumn.children.reduce(
      (height, row) => height + (row.targetHeight ?? 0), 3)
  readonly property real naturalHeight: Shell.Theme.lerp(
      expandedNaturalHeight, collapsedNaturalHeight,
      Shell.Theme.collapseHeight(collapseProgress))
  readonly property bool workspaceNumbersRevealed: expandedLayer.enabled
      && (expandedComponentHover.hovered
          || (dragSession.active && (!dragSession.windowDrag || Shell.Theme.daylight)))

  focus: dragSession.active
  Keys.onEscapePressed: dragSession.cancel()
  onCollapseProgressChanged: if (collapseProgress >= 0.56) dragSession.cancel()

  Nirimap.DragSession {
    id: dragSession
    parent: root.Window.window?.contentItem ?? root
  }

  function windowIndex(workspaceId, items, index) {
    if (!dragSession.windowDrag || !dragSession.active)
      return index;
    const sourceIndex = items.findIndex(w => w.winId === dragSession.source.windowData.winId);
    const compact = index - (sourceIndex >= 0 && index > sourceIndex ? 1 : 0);
    return compact + (dragSession.destination?.workspaceId === workspaceId
        && compact >= dragSession.destination.slot ? 1 : 0);
  }

  function rowOffset(workspaceId, number) {
    if (!dragSession.active || dragSession.windowDrag || number < 1)
      return 0;
    const source = dragSession.source;
    if (source.workspaceId === workspaceId)
      return dragSession.rowOffset;
    const target = dragSession.destination?.number ?? source.number;
    if (number > source.number && number <= target) return -Shell.Theme.workspaceControlPitch;
    if (number < source.number && number >= target) return Shell.Theme.workspaceControlPitch;
    return 0;
  }

  function numberedWorkspaceCount() {
    let count = 0;
    for (let i = 0; i < Shell.NiriMsg.workspaceRows.count; i++) {
      const row = Shell.NiriMsg.workspaceRows.get(i);
      if (!root.screen || row.outputName === "" || row.outputName === root.screen.name)
        count = Math.max(count, row.sidebarWorkspaceNumber);
    }
    return count;
  }
  width: Shell.Theme.lerp(Shell.Theme.sidebarCardExpandedWidth,
      Shell.Theme.sidebarCardCollapsedWidth, widthProgress)
  height: Math.min(maximumHeight, naturalHeight)
  radius: Shell.Theme.daylight ? 12 : Shell.Theme.sidebarCardRadius
  color: Shell.Theme.daylight
      ? (cardHovered || (dragSession.active && dragSession.windowDrag)
          ? Shell.Theme.sidebarHoverFill : Shell.Theme.sidebarClearFill)
      : classicColor
  // The number hit target reaches ten pixels outside the expanded card. The
  // panel gutter contains it; clipping returns once the compact layer takes
  // over so its top and bottom rows retain the card radius.
  clip: collapseProgress >= 0.56

  Item {
    id: expandedLayer
    x: -10
    width: root.width - x
    height: root.height
    clip: true
    opacity: root.expandedOpacity
    visible: opacity > 0.001
    enabled: root.collapseProgress < 0.56

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
          readonly property var activeWindowId: model.activeWindowId
          property int windowStart: 0
          property var firstWindowId: null

          onWindowItemsChanged: Qt.callLater(updateWindowStart)
          onActiveWindowIdChanged: Qt.callLater(updateWindowStart)

          function updateWindowStart() {
            const columns = Shell.Theme.workspaceGridColumns;
            // Preserve the first icon when windows before it close or move.
            const first = windowItems.findIndex(w => w.winId === firstWindowId);
            let start = first < 0 ? windowStart : first;
            const active = windowItems.findIndex(w => w.winId === activeWindowId);
            if (active >= 0)
              start = Math.max(active - columns + 1, Math.min(start, active));
            windowStart = Math.max(0, Math.min(start, windowItems.length - columns));
            firstWindowId = windowItems[windowStart]?.winId ?? null;
          }

          readonly property int carouselSlotCount: Math.max(
              Shell.Theme.workspaceGridColumns, windowItems.length + 1)
          readonly property int workspaceNumber:
              Number(expandedWorkspace.model.sidebarWorkspaceNumber) || 0
          readonly property bool dragTarget: dragSession.windowDrag
              && dragSession.destination?.workspaceId === Number(model.workspaceId)
          readonly property int remainingWindows: windowItems.filter(w =>
              !dragSession.windowDrag || w.winId !== dragSession.source.windowData.winId).length
          property real dragOffset: root.rowOffset(Number(model.workspaceId), workspaceNumber)
          visible: matchesOutput
          width: expandedColumn.width
          height: matchesOutput ? Shell.Theme.workspaceControlSize : 0
          z: dragSession.source?.kind === "workspace"
              && dragSession.source.workspaceId === Number(model.workspaceId) ? 20 : 0
          transform: Translate { y: expandedWorkspace.dragOffset }
          Behavior on dragOffset {
            enabled: !dragSession.resetting && !dragSession.committing
                && !(dragSession.held && expandedWorkspace.z === 20)
            Shell.HoverAnimation { duration: Shell.Theme.workspaceDragSnapDuration }
          }
          Rectangle {
            x: Shell.Theme.workspaceActiveIndicatorInset - expandedLayer.x
            y: -Shell.Theme.workspaceControlGap / 2
            width: root.width - Shell.Theme.workspaceActiveIndicatorInset * 2
            height: parent.height + Shell.Theme.workspaceControlGap
            radius: 12
            color: expandedWorkspace.model.isActive || expandedWorkspace.dragTarget
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

          HoverHandler { id: rowHover; enabled: expandedLayer.enabled }

          Item {
            id: windowViewport
            x: Shell.Theme.lerp(Shell.Theme.workspaceContentPadding, 8, root.widthProgress) - expandedLayer.x
            width: Shell.Theme.workspaceGridColumns * Shell.Theme.workspaceControlSize
                + (Shell.Theme.workspaceGridColumns - 1)
                  * Shell.Theme.workspaceControlGap
            height: parent.height
            clip: true

            Item {
              id: windowCarousel
              x: -expandedWorkspace.windowStart
                  * Shell.Theme.workspaceControlPitch * (1 - root.widthProgress)
              width: expandedWorkspace.carouselSlotCount
                  * Shell.Theme.workspaceControlSize
                  + (expandedWorkspace.carouselSlotCount - 1)
                    * Shell.Theme.workspaceControlGap
              height: parent.height

              Behavior on x { enabled: root.collapseProgress === 0; Shell.Motion { duration: 220 } }

              Repeater {
                // Keep every window instantiated as the displayed range slides.
                model: expandedWorkspace.carouselSlotCount

                delegate: Item {
                  id: workspaceSlot

                  required property int index

                  readonly property bool hasWindow:
                      index < expandedWorkspace.windowItems.length
                  readonly property bool addSlot: index === expandedWorkspace.windowItems.length
                  readonly property bool plusRevealed: addSlot && root.collapseProgress === 0
                      && expandedWorkspace.matchesOutput && !dragSession.active && (rowHover.hovered
                          || (!expandedWorkspace.model.outputHasWindows && expandedWorkspace.model.isCreationRow))
                  readonly property var windowData: hasWindow
                      ? expandedWorkspace.windowItems[index] : ({})
                  readonly property bool emptyWorkspaceActive: index === 0
                      && expandedWorkspace.windowItems.length === 0
                      && expandedWorkspace.model.isActive
                  readonly property int visualIndex: root.windowIndex(Number(expandedWorkspace.model.workspaceId),
                      expandedWorkspace.windowItems, index)
                  readonly property bool daylightDropTarget: Shell.Theme.daylight && expandedWorkspace.dragTarget
                      && visualIndex === dragSession.destination?.slot

                  visible: root.collapseProgress === 0 || (index >= expandedWorkspace.windowStart
                      && index < expandedWorkspace.windowStart + Shell.Theme.workspaceGridColumns)
                  x: visualIndex * Shell.Theme.workspaceControlPitch * (1 - root.widthProgress)
                  width: Shell.Theme.lerp(Shell.Theme.workspaceControlSize,
                      Shell.Theme.workspaceCollapsedControlSize, root.widthProgress)
                  height: width
                  Behavior on x {
                    enabled: root.collapseProgress === 0 && workspaceSlot.hasWindow && !dragSession.resetting && !dragSession.committing
                    Shell.HoverAnimation { duration: Shell.Theme.workspaceDragSnapDuration }
                  }

                  Rectangle {
                    anchors.fill: parent
                    visible: workspaceSlot.emptyWorkspaceActive && !workspaceSlot.daylightDropTarget
                    radius: width / 2
                    color: Shell.Theme.workspaceLauncherActive
                    border.color: Shell.Theme.daylight ? Shell.Theme.workspaceIconOutline : Shell.Theme.sidebarV3Border
                    border.width: Shell.Theme.sidebarStrokeWidth
                    antialiasing: true
                  }

                  Rectangle {
                    anchors.centerIn: parent
                    visible: root.collapseProgress === 0 && !workspaceSlot.hasWindow && !workspaceSlot.emptyWorkspaceActive
                        && (!dragSession.active || Shell.Theme.daylight) && !workspaceSlot.daylightDropTarget
                    width: Shell.Theme.workspacePlaceholderDotSize
                    height: Shell.Theme.workspacePlaceholderDotSize
                    radius: width / 2
                    color: Shell.Theme.workspacePlaceholderColor
                    opacity: workspaceSlot.plusRevealed ? 0 : 1
                    Behavior on opacity { Shell.HoverAnimation {} }
                  }

                  Nirimap.WindowIcon {
                    id: windowIcon
                    anchors.fill: parent
                    visible: workspaceSlot.hasWindow
                    opacity: dragSession.windowDrag
                        && dragSession.source.windowData.winId === workspaceSlot.windowData.winId ? 0 : 1
                    controlSize: workspaceSlot.width
                    windowData: workspaceSlot.windowData
                    onActivated: windowId => root.windowRequested(windowId)

                    DragHandler {
                      id: windowDrag
                      target: null
                      enabled: expandedLayer.enabled && workspaceSlot.hasWindow
                          && (!dragSession.active || active)
                      acceptedButtons: Qt.LeftButton
                      dragThreshold: 6
                      cursorShape: active ? Qt.ClosedHandCursor : Qt.PointingHandCursor
                      onActiveChanged: {
                        if (active) dragSession.begin({ kind: "window",
                            windowData: Object.assign({}, workspaceSlot.windowData),
                            slot: workspaceSlot.index,
                            workspaceId: Number(expandedWorkspace.model.workspaceId) },
                            windowIcon, centroid.scenePressPosition, centroid.scenePosition);
                        else dragSession.release();
                      }
                      onCentroidChanged: if (active) dragSession.move(centroid.scenePosition)
                      onCanceled: dragSession.cancel()
                    }
                  }

                  Nirimap.PlusButton {
                    anchors.fill: parent
                    revealed: workspaceSlot.plusRevealed
                    enabled: expandedLayer.enabled && !dragSession.active
                    onActivated: root.addRequested(Number(expandedWorkspace.model.workspaceId))
                  }
                }
              }

              Repeater {
                parent: expandedLayer
                model: expandedWorkspace.carouselSlotCount
                DropArea {
                  id: windowDrop
                  required property int index
                  readonly property int workspaceId: Number(expandedWorkspace.model.workspaceId)
                  readonly property int slot: Math.min(index, expandedWorkspace.remainingWindows)
                  readonly property real slotX: windowViewport.x + windowCarousel.x
                      + index * Shell.Theme.workspaceControlPitch - Shell.Theme.workspaceControlGap / 2
                  x: Math.max(windowViewport.x, slotX)
                  y: expandedColumn.y + expandedWorkspace.y + 4
                  width: Math.max(0, Math.min(windowViewport.x + windowViewport.width, slotX + 48) - x)
                  height: 56
                  keys: ["pond-window"]
                  enabled: expandedLayer.enabled && index <= expandedWorkspace.remainingWindows
                  onEntered: dragSession.destination = windowDrop
                  onExited: if (dragSession.held && dragSession.destination === windowDrop) dragSession.destination = null
                  onDropped: drop => drop.acceptProposedAction()
                  function snapPosition() {
                    return windowCarousel.mapToItem(dragSession.parent,
                        slot * Shell.Theme.workspaceControlPitch, 0);
                  }
                }
              }

              Shape {
                visible: expandedWorkspace.dragTarget
                x: (dragSession.destination?.slot ?? 0) * Shell.Theme.workspaceControlPitch
                width: Shell.Theme.workspaceControlSize
                height: width
                antialiasing: true
                Behavior on x { Shell.HoverAnimation { duration: Shell.Theme.workspaceDragSnapDuration } }
                ShapePath {
                  strokeColor: Shell.Theme.daylight ? Shell.Theme.workspaceDropFill : "#4F3D64"
                  strokeWidth: 1
                  strokeStyle: Shell.Theme.daylight ? ShapePath.SolidLine : ShapePath.DashLine
                  dashPattern: [3, 3]
                  capStyle: ShapePath.RoundCap
                  fillColor: Shell.Theme.daylight ? Shell.Theme.workspaceDropFill : "#191919"
                  PathRectangle { x: 0.5; y: 0.5; width: 39; height: 39; radius: 20 }
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
                  || (Shell.Theme.daylight && dragSession.active && dragSession.windowDrag)
                  ? Shell.Theme.workspaceNumberDragBackground : Shell.Theme.workspaceNumberBackground
              antialiasing: true
              Behavior on color { ColorAnimation { duration: 120; easing.type: Easing.OutCubic } }
              Text {
                anchors.fill: parent
                visible: !numberPointer.containsMouse && !workspaceDrag.active
                text: expandedWorkspace.workspaceNumber
                color: Shell.Theme.daylight ? "white" : Shell.Theme.sidebarV3Foreground
                font.family: Shell.Theme.plexFontFamily
                font.weight: Font.Medium
                font.pixelSize: 11
                font.letterSpacing: 0.11
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
              }
              Image {
                anchors.centerIn: parent
                width: 2
                height: 10
                visible: numberPointer.containsMouse || workspaceDrag.active
                source: "../assets/navigation/drag-handle.svg"
              }
            }
            MouseArea {
              id: numberPointer
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: workspaceDrag.active ? Qt.ClosedHandCursor : Qt.OpenHandCursor
              onClicked: root.focusRequested(expandedWorkspace.model.workspaceIndex)
            }
            DragHandler {
              id: workspaceDrag
              target: null
              enabled: expandedLayer.enabled && (!dragSession.active || active)
              acceptedButtons: Qt.LeftButton
              dragThreshold: 6
              xAxis.enabled: false
              onActiveChanged: {
                if (active) dragSession.begin({ kind: "workspace",
                    workspaceId: Number(expandedWorkspace.model.workspaceId),
                    number: expandedWorkspace.workspaceNumber,
                    count: root.numberedWorkspaceCount() }, expandedWorkspace,
                    centroid.scenePressPosition, centroid.scenePosition);
                else dragSession.release();
              }
              onCentroidChanged: if (active) dragSession.move(centroid.scenePosition)
              onCanceled: dragSession.cancel()
            }
          }

          DropArea {
            id: workspaceDrop
            parent: expandedLayer
            readonly property int workspaceId: Number(expandedWorkspace.model.workspaceId)
            readonly property int number: expandedWorkspace.workspaceNumber
            x: 0
            y: expandedColumn.y + expandedWorkspace.y - Shell.Theme.workspaceControlGap / 2
            width: 20
            height: Shell.Theme.workspaceControlPitch
            keys: ["pond-workspace"]
            enabled: expandedLayer.enabled && number > 0 && expandedWorkspace.matchesOutput
            onEntered: dragSession.destination = workspaceDrop
            onExited: if (dragSession.held && dragSession.destination === workspaceDrop) dragSession.destination = null
            onDropped: drop => drop.acceptProposedAction()
            function snapPosition() {
              return expandedColumn.mapToItem(dragSession.parent, 0, expandedWorkspace.y);
            }
          }
        }
      }
    }

    Column {
      visible: root.collapseProgress === 0
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
                color: Shell.Theme.workspacePlaceholderColor
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
    enabled: root.collapseProgress >= 0.56

    Column {
      id: collapsedColumn
      y: Shell.Theme.lerp(Shell.Theme.workspaceContentPadding, 0, root.heightProgress)
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
          property real targetHeight: !matchesOutput ? 0
              : (active ? Math.max(42, activeHeight) : 41)
          height: matchesOutput ? Shell.Theme.lerp(Shell.Theme.workspaceControlPitch,
              targetHeight, root.heightProgress) : 0

          Behavior on targetHeight {
            enabled: root.collapseProgress === 1
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

          Item {
            visible: collapsedWorkspace.active
            x: 8
            y: Shell.Theme.workspaceCollapsedHeaderHeight * root.heightProgress
            width: Shell.Theme.workspaceCollapsedControlSize
            height: collapsedWorkspace.windowItems.length * Shell.Theme.workspaceCollapsedControlPitch

            Repeater {
              // Keep delegates alive when focus, title or activity changes.
              // An array model destroys them on every new JSON snapshot.
              model: collapsedWorkspace.windowItems.length

              delegate: Nirimap.WindowIcon {
                required property int index
                y: index * Shell.Theme.workspaceCollapsedControlPitch * root.heightProgress
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
