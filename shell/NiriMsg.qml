pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
  id: root

  property var workspaces: []
  property var _windows: ({})
  property var _appInfoCache: ({})
  property int sidebarWidth: 166
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

  function focusApp(appName, desktopEntry) {
    function normalize(value) {
      return String(value || "").toLowerCase().replace(/[^a-z0-9]+/g, "");
    }

    const wanted = [normalize(desktopEntry), normalize(appName)]
        .filter(value => value.length >= 2);
    if (wanted.length === 0)
      return false;

    for (const id in _windows) {
      const windowData = _windows[id];
      const appId = normalize(windowData.appId);
      if (appId === "")
        continue;
      for (const candidate of wanted) {
        if (appId === candidate || appId.includes(candidate)
            || candidate.includes(appId)) {
          focusWindow(windowData.id);
          return true;
        }
      }
    }
    return false;
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
    if (ev.WorkspacesChanged) {
      const list = ev.WorkspacesChanged.workspaces.map(w => ({
        id: w.id, idx: w.idx, name: w.name || "", output: w.output || "",
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
    } else if (ev.WindowsChanged) {
      const wins = {};
      for (const w of ev.WindowsChanged.windows)
        wins[w.id] = _mapWindow(w);
      _windows = wins;
    } else if (ev.WindowOpenedOrChanged) {
      const w = _mapWindow(ev.WindowOpenedOrChanged.window);
      const wins = Object.assign({}, _windows);
      if (w.isFocused)
        for (const id in wins) wins[id].isFocused = false;
      wins[w.id] = w;
      _windows = wins;
    } else if (ev.WindowClosed) {
      const wins = Object.assign({}, _windows);
      delete wins[ev.WindowClosed.id];
      _windows = wins;
    } else if (ev.WindowFocusChanged) {
      const fid = ev.WindowFocusChanged.id;
      const wins = Object.assign({}, _windows);
      for (const id in wins) wins[id].isFocused = (wins[id].id === fid);
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
      id: w.id, workspaceId: w.workspace_id, isFocused: w.is_focused,
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

  function _outputSize(outputName) {
    for (let i = 0; i < Quickshell.screens.length; i++) {
      const screen = Quickshell.screens[i];
      if (!outputName || screen.name === outputName)
        return { width: screen.width, height: screen.height };
    }
    return { width: 1920, height: 1080 };
  }

  function _isWindowVisible(w, workspaceActive, outputName) {
    if (!workspaceActive)
      return false;

    const layout = w.layout || {};
    const pos = layout.tile_pos_in_workspace_view;
    const size = layout.tile_size || layout.window_size;

    // Niri does not expose workspace-view geometry for every floating window.
    // Floating windows on the active workspace are therefore visible unless a
    // concrete rectangle proves otherwise.
    if (!pos || !size)
      return w.isFloating || w.isFocused;

    const viewport = _outputSize(outputName);
    const centerX = pos[0] + size[0] / 2;
    const centerY = pos[1] + size[1] / 2;

    // Niri leaves neighboring columns a few pixels inside the output while
    // they are effectively off-screen. Treat a tile as visible when its
    // center is inside the usable view, which maps the markers to the columns
    // the user can actually see instead of counting those edge slivers.
    return centerX >= sidebarWidth
        && centerX < viewport.width
        && centerY >= 0
        && centerY < viewport.height;
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
      let visibleCount = 0;
      let focusedIndex = 0;

      for (const w of wsWindows) {
        const info = _appInfo(w.appId);
        const isVisible = _isWindowVisible(w, ws.isActive, ws.output);
        if (w.isFocused) focusedIndex = windowRecords.length;
        if (isVisible)
          visibleCount++;
        windowRecords.push({
          winId: w.id,
          iconName: info.iconName,
          iconSource: info.iconSource,
          isVisible: isVisible
        });
      }

      // During startup or a compositor transition, layout geometry can be
      // momentarily absent. Keep the focused (or first) window represented as
      // visible rather than flashing every marker to the outlined state.
      if (ws.isActive && windowRecords.length > 0 && visibleCount === 0) {
        windowRecords[focusedIndex].isVisible = true;
      }

      let lastVisible = -1;
      for (let i = 0; i < windowRecords.length; i++) {
        if (windowRecords[i].isVisible)
          lastVisible = i;
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
        windowsJson: JSON.stringify(windowRecords),
        carouselStart: ws.isActive
            && lastVisible >= Theme.workspaceGridColumns
            ? lastVisible - Theme.workspaceGridColumns + 1 : 0,
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
