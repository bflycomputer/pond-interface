pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import ".." as Shell

Singleton {
  id: root
  property var historyNotifications: []
  property var activeNotifications: []
  readonly property var recentApps: _recentApps(historyNotifications)
  property string transientId: ""
  property string transientOutputName: ""
  readonly property var currentTransient: _findById(activeNotifications, transientId)
  readonly property bool transientVisible: transientId !== "" && currentTransient !== null && !panelOpen
  property bool panelOpen: false
  property string panelOutputName: ""
  readonly property int notificationCount: historyNotifications.length
  property var live: ({})
  property bool historyWritable: false

  FileView {
    id: history
    path: (Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state")
        + "/pond-default/notifications.json"
    blockLoading: true
    atomicWrites: true
    printErrors: false
    onSaveFailed: error => console.warn("Saving notification history:", error)
  }

  Component.onCompleted: {
    try {
      historyNotifications = JSON.parse(history.text() || "{}").notifications || [];
      historyWritable = true;
    } catch (error) {
      // Preserve unreadable history before starting a fresh file.
      recover.command = ["mv", "--", history.path, history.path + ".unreadable-" + Date.now()];
      recover.running = true;
    }
  }

  Process {
    id: recover
    onExited: code => {
      root.historyWritable = code === 0;
      if (root.historyWritable) save.restart();
      else console.warn("Could not preserve unreadable notification history:", history.path);
    }
  }

  onHistoryNotificationsChanged: {
    if (historyWritable) save.restart();
    if (historyNotifications.length === 0) closePanel();
  }
  Timer {
    id: save
    interval: 50
    onTriggered: history.setText(JSON.stringify({ notifications: root.historyNotifications }))
  }

  NotificationServer {
    keepOnReload: true
    persistenceSupported: true
    actionsSupported: true
    bodySupported: true
    bodyMarkupSupported: false
    imageSupported: false
    onNotification: notification => root.receive(notification)
  }

  function snapshot(n, id) {
    const saved = _findById(historyNotifications, id) || _findById(activeNotifications, id);
    return { id, summary: n.summary, body: n.body, appName: n.appName,
      appIcon: n.appIcon, desktopEntry: n.desktopEntry,
      timestamp: saved ? saved.timestamp : Date.now() };
  }

  function receive(notification) {
    notification.tracked = true;
    const id = Quickshell.processId + ":" + notification.id;
    if (!live[id]) live[id] = watcher.createObject(root, { notification, notificationId: id });
    live[id].refresh();
    if (!notification.lastGeneration && !panelOpen) {
      transientOutputName = Shell.NiriMsg.focusedOutputName || Quickshell.screens[0]?.name || "";
      transientId = id;
    }
  }

  Component {
    id: watcher
    Scope {
      id: entry
      required property var notification
      required property string notificationId
      property bool closed: false

      function refresh() {
        if (closed) return;
        const data = root.snapshot(notification, notificationId);
        root.activeNotifications = [data, ...root.activeNotifications.filter(n => n.id !== notificationId)];
        if (!notification.transient)
          root.historyNotifications = [data, ...root.historyNotifications.filter(n => n.id !== notificationId)];
        expiry.restart();
      }
      function scheduleRefresh() { Qt.callLater(refresh); }
      Timer {
        id: expiry
        interval: [3000, 8000, 15000][entry.notification.urgency] || 8000
        onTriggered: entry.notification.expire()
      }
      Connections {
        target: entry.notification
        function onSummaryChanged() { entry.scheduleRefresh(); }
        function onBodyChanged() { entry.scheduleRefresh(); }
        function onAppIconChanged() { entry.scheduleRefresh(); }
        function onClosed(reason) {
          entry.closed = true;
          if (root.transientId === entry.notificationId) root.transientId = "";
          root.activeNotifications = root.activeNotifications.filter(n => n.id !== entry.notificationId);
          delete root.live[entry.notificationId];
          entry.destroy();
        }
      }
    }
  }

  function _findById(items, id) {
    if (!id)
      return null;
    for (const item of items) {
      if (item.id === id)
        return item;
    }
    return null;
  }

  function _identity(notification) {
    const raw = notification.desktopEntry || notification.appName || "unknown";
    return raw.toLowerCase().replace(/[^a-z0-9]+/g, "");
  }

  function _recentApps(items) {
    const seen = ({});
    const result = [];
    for (const item of items) {
      const key = _identity(item);
      if (seen[key])
        continue;
      seen[key] = true;
      result.push({
                    identity: key,
                    name: item.appName,
                    iconSource: iconSource(item)
                  });
      if (result.length >= 5)
        break;
    }
    return result;
  }

  function iconSource(notification) {
    const rawIcon = String(notification.appIcon || "");
    if (rawIcon.startsWith("file:") || rawIcon.startsWith("image:")
        || rawIcon.startsWith("qrc:"))
      return rawIcon;
    if (rawIcon.startsWith("/"))
      return "file://" + rawIcon;
    if (rawIcon !== "")
      return Quickshell.iconPath(rawIcon, "application-x-executable");

    const candidates = [notification.desktopEntry, notification.appName];
    for (const candidate of candidates) {
      if (!candidate)
        continue;
      try {
        const lower = String(candidate).toLowerCase();
        const entry = DesktopEntries.byId(candidate)
            || DesktopEntries.byId(lower)
            || DesktopEntries.heuristicLookup(candidate)
            || DesktopEntries.heuristicLookup(lower);
        if (entry && entry.icon)
          return Quickshell.iconPath(entry.icon, "application-x-executable");
      } catch (error) {}
    }

    const fallback = String(notification.appName || "application-x-executable")
        .toLowerCase().replace(/\s+/g, "-");
    return Quickshell.iconPath(fallback, "application-x-executable");
  }

  function title(notification) {
    if (!notification)
      return "";
    return notification.summary ? String(notification.summary)
                                : String(notification.appName || "");
  }

  function message(notification) {
    if (!notification)
      return "";
    return notification.body ? String(notification.body)
                             : String(notification.summary || "");
  }

  function timeLabel(timestamp) {
    const date = new Date(Number(timestamp));
    let hours = date.getHours();
    const suffix = hours >= 12 ? "PM" : "AM";
    hours = hours % 12;
    if (hours === 0)
      hours = 12;
    const minutes = String(date.getMinutes()).padStart(2, "0");
    return hours + ":" + minutes + " " + suffix;
  }

  function togglePanel(outputName) {
    if (notificationCount === 0) return;
    if (panelOpen && panelOutputName === outputName) { closePanel(); return; }
    transientId = "";
    panelOutputName = outputName;
    panelOpen = true;
  }

  function closePanel() { panelOpen = false; }

  function remove(notification) {
    if (!notification || !notification.id) return;
    const id = notification.id;
    if (transientId === id) transientId = "";
    historyNotifications = historyNotifications.filter(n => n.id !== id);
    activeNotifications = activeNotifications.filter(n => n.id !== id);
    if (live[id]) live[id].notification.dismiss();
  }

  function activate(notification) {
    if (!notification || !notification.id) return;
    const n = live[notification.id]?.notification;
    const action = n?.actions.find(a => a.identifier === "default");
    if (action) action.invoke();
    else Shell.NiriMsg.focusApp(notification.appName, notification.desktopEntry);
    remove(notification);
    transientId = "";
    closePanel();
  }

  function clearAll() {
    for (const id of Object.keys(live))
      live[id]?.notification.dismiss();
    historyNotifications = [];
    activeNotifications = [];
    transientId = "";
    closePanel();
  }
}
