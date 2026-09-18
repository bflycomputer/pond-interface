pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
  id: root

  property var workspaces: []
  property bool overviewOpen: false
  property var dragOrigin: null
  property var _windows: ({})
  property var _appInfoCache: ({})
  property ListModel workspaceRows: ListModel {}
  readonly property string focusedOutputName: {
    for (const workspace of workspaces) {
      if (workspace.isFocused)
        return String(workspace.output || "");
    }
    return "";
  }
  function focusWindow(id) {
    Quickshell.execDetached(["niri", "msg", "action", "focus-window", "--id", String(id)]);
  }

  function focusWorkspace(index) {
    if (index === undefined || index < 0)
      return;
    Quickshell.execDetached(["niri", "msg", "action", "focus-workspace", String(index)]);
  }

  function moveWindow(id, workspaceId, slot, done) {
    const actions = _windowMoveActions(id, workspaceId, slot);
    return actions !== null && _move(actions, done);
  }

  function _windowMoveActions(id, workspaceId, slot) {
    const window = _windows[id];
    if (!window || !workspaces.some(w => w.id === workspaceId))
      return null;
    const actions = [];
    if (window.workspaceId !== workspaceId)
      actions.push({ MoveWindowToWorkspace: { window_id: id,
        reference: { Id: workspaceId }, focus: false } });
    if (window.isFloating)
      actions.push({ MoveWindowToTiling: { id: id } });
    else if (window.workspaceId === workspaceId && Object.values(_windows).filter(w =>
        w.workspaceId === workspaceId && !w.isFloating
        && _layoutPos(w)[0] === _layoutPos(window)[0]).length > 1)
      actions.push({ ConsumeOrExpelWindowRight: { id: id } });
    actions.push({ FocusWindow: { id: id } }, { MoveColumnToIndex: { index: slot + 1 } });
    return actions;
  }

  function windowExists(id) { return _windows[id] !== undefined; }

  function showWindowOverview(id, done) {
    const window = _windows[id];
    const workspace = workspaces.find(w => w.id === window?.workspaceId);
    if (!workspace || dragOrigin) return false;
    dragOrigin = Object.assign({}, window, { workspaceName: workspace.name,
      overviewOpen: overviewOpen, stackSize: Object.values(_windows).filter(w =>
        w.workspaceId === window.workspaceId && !w.isFloating
        && _layoutPos(w)[0] === _layoutPos(window)[0]).length });
    const actions = [{ FocusWindow: { id: id } }];
    // Keep the source workspace available if its last window is previewed elsewhere.
    if (!workspace.name)
      actions.push({ SetWorkspaceName: { workspace: { Id: workspace.id },
        name: "pond-drag-" + Quickshell.processId + "-" + workspace.id } });
    actions.push({ OpenOverview: {} });
    return _move(actions, done);
  }

  function finishWindowDrag(restore, done) {
    const origin = dragOrigin;
    if (!origin) return false;
    const actions = restore && windowExists(origin.id)
        ? _windowMoveActions(origin.id, origin.workspaceId,
            Math.max(0, _layoutPos(origin)[0] - 1)) : [];
    if (!actions) return false;
    if (restore && windowExists(origin.id)) {
      if (origin.isFloating)
        actions.push({ MoveWindowToFloating: { id: origin.id } });
      else if (origin.stackSize > 1) {
        actions.push({ ConsumeOrExpelWindowRight: { id: origin.id } });
        for (let row = origin.stackSize; row > _layoutPos(origin)[1]; row--)
          actions.push({ MoveWindowUp: {} });
      }
    }
    if (!origin.workspaceName)
      actions.push({ UnsetWorkspaceName: { reference: { Id: origin.workspaceId } } });
    actions.push(origin.overviewOpen ? { OpenOverview: {} } : { CloseOverview: {} });
    return _move(actions, success => {
      dragOrigin = null;
      _recompute();
      done(success);
    });
  }

  function moveWorkspace(id, targetId, done) {
    const target = workspaces.find(w => w.id === targetId);
    if (!target || !workspaces.some(w => w.id === id && w.output === target.output))
      return false;
    return _move([{ MoveWorkspaceToIndex: { reference: { Id: id }, index: target.idx } }], done);
  }

  property var _moveActions: []
  property var _moveDone: null

  function _move(actions, done) {
    if (_moveDone)
      return false;
    _moveActions = actions;
    _moveDone = done;
    moveTimeout.restart();
    moveSocket.connected = true;
    return true;
  }

  function _nextMoveAction() {
    if (_moveActions.length === 0) {
      _finishMove(true);
      return;
    }
    moveSocket.write(JSON.stringify({ Action: _moveActions.shift() }) + "\n");
    moveSocket.flush();
  }

  function _finishMove(success) {
    const done = _moveDone;
    _moveDone = null;
    _moveActions = [];
    moveTimeout.stop();
    moveSocket.connected = false;
    if (done)
      done(success);
  }

  Socket {
    id: moveSocket
    path: Quickshell.env("NIRI_SOCKET")
    onConnectedChanged: {
      if (connected) root._nextMoveAction();
      else if (root._moveDone) root._finishMove(false);
    }
    onError: root._finishMove(false)
    parser: SplitParser {
      onRead: line => {
        const reply = JSON.parse(line);
        if (reply.Err) root._finishMove(false);
        else root._nextMoveAction();
      }
    }
  }

  Timer {
    id: moveTimeout
    interval: 1500
    onTriggered: root._finishMove(false)
  }

  function appMatches(appId, appName, desktopEntry) {
    function normalize(value) {
      return String(value || "").toLowerCase().replace(/\.desktop$/, "").replace(/[^a-z0-9]+/g, "");
    }
    const wanted = desktopEntry || appName;
    if (!appId || !wanted) return false;
    const entry = DesktopEntries.heuristicLookup(appId);
    const target = DesktopEntries.heuristicLookup(wanted);
    if (entry && target) return entry.id === target.id;
    return [appId, entry?.id, entry?.name].some(value => normalize(value) === normalize(wanted));
  }

  function focusApp(appName, desktopEntry) {
    const window = Object.values(_windows).find(w => appMatches(w.appId, appName, desktopEntry));
    if (window) focusWindow(window.id);
    return !!window;
  }

  Process {
    id: stream
    command: ["niri", "msg", "-j", "event-stream"]
    running: true
    stdout: SplitParser {
      onRead: line => {
        try {
          root._handleEvent(JSON.parse(line));
        } catch (e) {
          console.log("pond: bad event line:", e);
        }
      }
    }
    onExited: restartTimer.start()
  }

  Timer {
    id: restartTimer
    interval: 1500
    onTriggered: stream.running = true
  }

  function _handleEvent(ev) {
    if (ev.OverviewOpenedOrClosed) {
      overviewOpen = ev.OverviewOpenedOrClosed.is_open;
      return;
    } else if (ev.WorkspacesChanged) {
      const list = ev.WorkspacesChanged.workspaces.map(w => ({
        id: w.id, idx: w.idx, name: w.name || "", output: w.output || "",
        activeWindowId: w.active_window_id,
        isActive: !!w.is_active, isFocused: !!w.is_focused, isUrgent: !!w.is_urgent
      }));
      list.sort((a, b) => {
        const outputOrder = a.output.localeCompare(b.output);
        return outputOrder !== 0 ? outputOrder : a.idx - b.idx;
      });
      workspaces = list;
    } else if (ev.WorkspaceActivated) {
      const a = ev.WorkspaceActivated;
      const target = workspaces.find(w => w.id === a.id);
      workspaces = workspaces.map(w => Object.assign({}, w, {
        isActive: target && w.output === target.output ? w.id === a.id : w.isActive,
        isFocused: a.focused ? w.id === a.id : w.isFocused
      }));
    } else if (ev.WorkspaceActiveWindowChanged) {
      const a = ev.WorkspaceActiveWindowChanged;
      workspaces = workspaces.map(w => w.id === a.workspace_id
          ? Object.assign({}, w, { activeWindowId: a.active_window_id }) : w);
    } else if (ev.WindowsChanged) {
      const wins = {};
      for (const w of ev.WindowsChanged.windows)
        wins[w.id] = _mapWindow(w);
      _windows = wins;
    } else if (ev.WindowOpenedOrChanged) {
      const w = _mapWindow(ev.WindowOpenedOrChanged.window);
      const wins = Object.assign({}, _windows);
      wins[w.id] = w;
      _windows = wins;
    } else if (ev.WindowClosed) {
      const wins = Object.assign({}, _windows);
      delete wins[ev.WindowClosed.id];
      _windows = wins;
    } else if (ev.WindowLayoutsChanged) {
      const wins = Object.assign({}, _windows);
      for (const ch of ev.WindowLayoutsChanged.changes) {
        const id = Array.isArray(ch) ? ch[0] : ch.id;
        const layout = Array.isArray(ch) ? ch[1] : ch.layout;
        if (wins[id]) wins[id].layout = layout;
      }
      _windows = wins;
    } else {
      return;
    }
    _recompute();
  }

  function _mapWindow(w) {
    return {
      id: w.id, workspaceId: w.workspace_id,
      isFloating: w.is_floating, layout: w.layout, appId: w.app_id || ""
    };
  }

  function _appInfo(appId) {
    if (_appInfoCache[appId])
      return _appInfoCache[appId];
    const lower = appId.toLowerCase();
    const entry = DesktopEntries.heuristicLookup(appId)
           || DesktopEntries.byId(appId)
           || DesktopEntries.byId(lower)
           || DesktopEntries.heuristicLookup(lower);
    const iconName = entry?.icon || lower;
    const info = {
      iconName: iconName,
      iconSource: Quickshell.iconPath(iconName, "application-x-executable")
    };
    if (entry)
      _appInfoCache[appId] = info;
    return info;
  }

  function _wsIdxOf(wsId) {
    for (const ws of workspaces)
      if (ws.id === wsId) return ws.idx;
    return 999;
  }

  function _layoutPos(w) {
    return w.layout && w.layout.pos_in_scrolling_layout
      ? w.layout.pos_in_scrolling_layout : [999, 999];
  }

  function _compareWindows(a, b) {
    const ws = _wsIdxOf(a.workspaceId) - _wsIdxOf(b.workspaceId);
    if (ws !== 0) return ws;
    const ap = _layoutPos(a), bp = _layoutPos(b);
    if (ap[0] !== bp[0]) return ap[0] - bp[0];
    if (ap[1] !== bp[1]) return ap[1] - bp[1];
    return a.id - b.id;
  }

  function _recompute() {
    // The drag's source delegate and drop slots must survive live window moves.
    if (dragOrigin) return;
    // Annotate workspace occupancy for the sidebar.
    const occupied = {};
    for (const id in _windows) {
        occupied[_windows[id].workspaceId] = true;
    }
    let changed = false;
    const anno = workspaces.map(w => {
      const has = !!occupied[w.id];
      if (has !== w.hasWindows) changed = true;
      return Object.assign({}, w, { hasWindows: has });
    });
    if (changed) workspaces = anno;

    const list = [];
    for (const id in _windows) {
        list.push(_windows[id]);
    }
    list.sort(_compareWindows);

    const windowsByWorkspace = {};
    for (const w of list) {
      if (!windowsByWorkspace[w.workspaceId])
        windowsByWorkspace[w.workspaceId] = [];
      windowsByWorkspace[w.workspaceId].push(w);
    }

    // Include every occupied workspace and exactly one creation workspace per
    // output. An already-selected empty workspace is the creation row; only
    // append a trailing empty workspace when every selected row is occupied.
    const byOutput = {};
    for (const ws of anno) {
      const outputName = ws.output || "";
      if (!byOutput[outputName])
        byOutput[outputName] = [];
      byOutput[outputName].push(ws);
    }

    const included = {};
    const creationRows = {};
    for (const outputName in byOutput) {
      const outputWorkspaces = byOutput[outputName];
      let anchorIndex = 0;
      let selectedEmpty = null;
      for (const ws of outputWorkspaces) {
        if (ws.hasWindows || ws.isActive || ws.isFocused)
          anchorIndex = Math.max(anchorIndex, ws.idx);
        if (ws.hasWindows || ws.isActive || ws.isFocused)
          included[ws.id] = true;
        if (!ws.hasWindows && (ws.isActive || ws.isFocused)
            && (!selectedEmpty || ws.isFocused))
          selectedEmpty = ws;
      }

      let creationWorkspace = selectedEmpty;
      if (!creationWorkspace) {
        for (const ws of outputWorkspaces) {
          if (!ws.hasWindows && ws.idx > anchorIndex
              && (!creationWorkspace || ws.idx < creationWorkspace.idx))
            creationWorkspace = ws;
        }
      }
      if (!creationWorkspace) {
        for (const ws of outputWorkspaces) {
          if (!ws.hasWindows && !included[ws.id]) {
            creationWorkspace = ws;
            break;
          }
        }
      }
      if (creationWorkspace) {
        included[creationWorkspace.id] = true;
        creationRows[creationWorkspace.id] = true;
      }
    }

    const rows = [];
    const rowOrdinals = {};
    const workspaceNumbers = {};
    for (const ws of anno) {
      if (!included[ws.id])
        continue;

      const wsWindows = windowsByWorkspace[ws.id] || [];
      const windowRecords = [];

      for (const w of wsWindows) {
        const info = _appInfo(w.appId);
        windowRecords.push({
          winId: w.id,
          iconName: info.iconName,
          iconSource: info.iconSource
        });
      }

      const outputName = ws.output || "";
      const rowOrdinal = rowOrdinals[outputName] || 0;
      rowOrdinals[outputName] = rowOrdinal + 1;
      const creationRow = !!creationRows[ws.id];
      const numberedRow = !creationRow || ws.isActive || ws.isFocused;
      let workspaceNumber = 0;
      if (numberedRow) {
        workspaceNumber = (workspaceNumbers[outputName] || 0) + 1;
        workspaceNumbers[outputName] = workspaceNumber;
      }

      rows.push({
        workspaceId: ws.id,
        workspaceIndex: ws.idx,
        outputName: outputName,
        isActive: !!ws.isActive,
        activeWindowId: ws.activeWindowId ?? -1,
        windowsJson: JSON.stringify(windowRecords),
        sidebarRowOrdinal: rowOrdinal,
        sidebarWorkspaceNumber: workspaceNumber
      });
    }

    _syncModel(workspaceRows, rows, "workspaceId");
  }

  function _syncModel(model, desired, identityKey) {
    for (let i = 0; i < desired.length; i++) {
      const d = desired[i];
      let j = -1;
      for (let s = i; s < model.count; s++) {
        if (model.get(s)[identityKey] === d[identityKey]) { j = s; break; }
      }
      if (j === -1) {
        model.insert(i, d);
        continue;
      }
      if (j !== i)
        model.move(j, i, 1);
      const cur = model.get(i);
      for (const key of Object.keys(d))
        if (cur[key] !== d[key])
          model.setProperty(i, key, d[key]);
    }
    while (model.count > desired.length)
      model.remove(model.count - 1);
  }
}
