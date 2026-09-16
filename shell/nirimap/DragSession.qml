import QtQuick
import "." as Nirimap
import ".." as Shell

Item {
  id: root
  property var source: null
  property Item destination: null
  property bool held: false
  property bool committing: false
  property bool resetting: false
  property bool preparingOverview: false
  property bool movingPreview: false
  property bool previewed: false
  property var applied: null
  onDestinationChanged: if (windowDrag && held) preview.restart()
  readonly property bool active: source !== null
  readonly property bool windowDrag: source?.kind === "window"
  property point origin
  property point press
  property point pointer
  property point grabOffset
  readonly property bool sourcePresent: !source || (windowDrag
      ? Shell.NiriMsg.windowExists(source.windowData.winId)
      : Shell.NiriMsg.workspaces.some(w => w.id === source.workspaceId))
  onSourcePresentChanged: if (!sourcePresent) cancel()
  readonly property real rowOffset: !source || windowDrag ? 0
      : held ? Math.max((1 - source.number) * Shell.Theme.workspaceControlPitch,
          Math.min((source.count - source.number) * Shell.Theme.workspaceControlPitch, pointer.y - press.y))
      : ((destination?.number ?? source.number) - source.number) * Shell.Theme.workspaceControlPitch

  z: 100
  width: Shell.Theme.workspaceControlSize
  height: width
  visible: active
  Drag.source: root
  Drag.keys: [windowDrag ? "pond-window" : "pond-workspace"]
  Drag.hotSpot.x: grabOffset.x
  Drag.hotSpot.y: grabOffset.y
  Drag.supportedActions: Qt.MoveAction
  Drag.proposedAction: Qt.MoveAction

  function begin(data, item, pressPoint, currentPoint) {
    if (active)
      return;
    source = data;
    origin = item.mapToItem(parent, 0, 0);
    press = parent.mapFromItem(null, pressPoint.x, pressPoint.y);
    grabOffset = Qt.point(press.x - origin.x, press.y - origin.y);
    held = true;
    move(currentPoint);
    Drag.active = true;
    if (windowDrag) {
      applied = { workspaceId: data.workspaceId, slot: data.slot };
      preparingOverview = Shell.NiriMsg.showWindowOverview(data.windowData.winId, success => {
        preparingOverview = false;
        if (!success) cancel();
        else if (held) preview.restart();
        else settle.restart();
      });
      if (!preparingOverview) cancel();
    }
  }

  function move(scenePoint) {
    if (!held)
      return;
    pointer = parent.mapFromItem(null, scenePoint.x, scenePoint.y);
    x = windowDrag ? pointer.x - grabOffset.x : origin.x;
    y = windowDrag ? pointer.y - grabOffset.y : origin.y + rowOffset;
  }

  function release() {
    if (!held)
      return;
    held = false;
    const accepted = Drag.drop() !== Qt.IgnoreAction;
    if (!accepted) destination = null;
    const target = destination ? destination.snapPosition() : origin;
    x = target.x;
    y = target.y;
    settle.restart();
  }

  function cancel() {
    if (!active || committing)
      return;
    Drag.cancel();
    destination = null;
    held = false;
    x = origin.x;
    y = origin.y;
    settle.restart();
  }

  function clear() {
    if (windowDrag && Shell.NiriMsg.finishWindowDrag(!destination && previewed, finish))
      return;
    finish();
  }

  function updatePreview() {
    if (preparingOverview || movingPreview) return;
    const target = destination
        ? { workspaceId: destination.workspaceId, slot: destination.slot } : null;
    if (!target || (applied?.workspaceId === target.workspaceId && applied.slot === target.slot)) {
      if (!held) clear();
      return;
    }
    movingPreview = Shell.NiriMsg.moveWindow(source.windowData.winId,
        target.workspaceId, target.slot, success => {
          movingPreview = false;
          if (success) applied = target;
          else { destination = null; held = false; }
          if (held) preview.restart();
          else settle.restart();
        });
    if (movingPreview) previewed = true;
    else { destination = null; held = false; clear(); }
  }

  function finish() {
    resetting = true;
    preview.stop();
    applied = null;
    previewed = false;
    source = null;
    destination = null;
    committing = false;
    Qt.callLater(() => resetting = false);
  }

  Timer {
    id: preview
    interval: 32
    onTriggered: if (root.held && root.windowDrag) root.updatePreview()
  }

  Timer {
    id: settle
    interval: Shell.Theme.workspaceDragSnapDuration
    onTriggered: {
      if (root.preparingOverview || root.movingPreview) return;
      if (root.windowDrag) {
        root.committing = true;
        root.updatePreview();
        return;
      }
      if (!root.destination) { root.clear(); return; }
      root.committing = true;
      const done = success => root.clear();
      const started = Shell.NiriMsg.moveWorkspace(root.source.workspaceId,
          root.destination.workspaceId, done);
      if (!started) root.clear();
    }
  }

  Behavior on x { enabled: !root.held; Shell.HoverAnimation { duration: Shell.Theme.workspaceDragSnapDuration } }
  Behavior on y { enabled: !root.held; Shell.HoverAnimation { duration: Shell.Theme.workspaceDragSnapDuration } }

  Nirimap.WindowIcon {
    anchors.fill: parent
    visible: root.windowDrag
    windowData: root.source?.windowData ?? ({})
    lifted: true
    interactive: false
  }
}
