pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "Networks.js" as NetworkUtils

// NetworkManager-backed authority for the custom Wi-Fi panel. All commands
// are argv arrays, so SSIDs and passwords never pass through a shell.
Singleton {
  id: root

  property bool enabled: true
  property string device: ""
  property string connectedSsid: ""
  property string connectedUuid: ""
  property var networks: []
  property string uploadRate: "0KB"
  property string downloadRate: "0KB"
  property string phase: "idle"
  property string statusText: ""
  property string pendingSsid: ""
  property bool panelOpen: false
  property var rateConsumers: []
  readonly property bool ratesRequested: panelOpen || rateConsumers.length > 0
  readonly property bool samplingRates: ratesRequested && device !== ""
  property string linkWidth: "—"
  property string negotiatedRate: "—"
  property var details: ({
    linkSpeed: "—",
    ipv4: "—",
    band: "—",
    gateway: "—",
    dns: "—",
    interfaceName: "—"
  })

  property real _lastTx: -1
  property real _lastRx: -1
  property double _lastByteTime: 0
  property string _actionKind: ""
  property string _actionError: ""
  property var _actionQueue: []
  property bool _actionSequenceActive: false

  signal actionFinished(string kind, bool success, string message)

  Component.onCompleted: refreshAll()

  onPanelOpenChanged: {
    if (panelOpen) {
      refreshAll();
      refreshDetails();
    }
  }

  onSamplingRatesChanged: resetRates()

  function setRateConsumer(consumer, active) {
    const next = rateConsumers.filter(item => item !== consumer);
    if (active)
      next.push(consumer);
    rateConsumers = next;
  }

  onDeviceChanged: {
    resetRates();
    linkWidth = "—";
    negotiatedRate = "—";
    details = { linkSpeed: "—", ipv4: "—", band: "—",
                gateway: "—", dns: "—", interfaceName: device || "—" };
  }

  function resetRates() {
    _lastTx = -1;
    _lastRx = -1;
    _lastByteTime = 0;
    uploadRate = "0B";
    downloadRate = "0B";
  }

  Process {
    id: networkMonitor
    command: ["/usr/bin/nmcli", "monitor"]
    environment: ({ "LC_ALL": "C" })
    running: true
    stdout: SplitParser {
      onRead: networkRefresh.restart()
    }
    onExited: monitorRestart.restart()
  }

  Timer {
    id: networkRefresh
    interval: 100
    onTriggered: root.refreshAll()
  }

  Timer {
    id: monitorRestart
    interval: 2000
    onTriggered: networkMonitor.running = true
  }

  function refreshAll() {
    if (!radioQuery.running) radioQuery.running = true;
    if (!deviceQuery.running) deviceQuery.running = true;
    if (!networkQuery.running) networkQuery.running = true;
  }

  function formatRate(bytesPerSecond) {
    const value = Math.max(0, Number(bytesPerSecond) || 0);
    if (value >= 1048576)
      return (value / 1048576).toFixed(value >= 10485760 ? 0 : 1) + "MB";
    if (value >= 1024)
      return (value / 1024).toFixed(value >= 10240 ? 0 : 1) + "KB";
    return Math.round(value) + "B";
  }

  function currentNetwork() {
    for (const network of networks) {
      if (network.connected)
        return network;
    }
    return null;
  }

  function setWifiEnabled(value) {
    runAction("toggle", ["/usr/bin/nmcli", "radio", "wifi",
                         value ? "on" : "off"], "");
  }

  function createUuid() {
    return "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx".replace(/[xy]/g, c => {
      const random = Math.floor(Math.random() * 16);
      const value = c === "x" ? random : (random & 0x3) | 0x8;
      return value.toString(16);
    });
  }

  function connectNetwork(ssid, password, hidden, securityMode) {
    const target = String(ssid || "");
    if (target === "")
      return;

    const mode = String(securityMode || "auto");
    if (mode !== "auto") {
      const uuid = createUuid();
      const addCommand = [
        "/usr/bin/nmcli", "connection", "add", "type", "wifi",
        "con-name", target, "connection.uuid", uuid,
        "802-11-wireless.ssid", target,
        "802-11-wireless.hidden", hidden ? "yes" : "no"
      ];
      if (device !== "")
        addCommand.push("ifname", device);

      const secret = String(password || "");
      switch (mode) {
      case "open":
        // An open connection has no wireless-security setting ("none" is WEP).
        break;
      case "owe":
        addCommand.push("802-11-wireless-security.key-mgmt", "owe");
        break;
      case "wpa":
        addCommand.push("802-11-wireless-security.key-mgmt", "wpa-psk",
                        "802-11-wireless-security.proto", "wpa",
                        "802-11-wireless-security.psk", secret);
        break;
      case "wpa2":
        addCommand.push("802-11-wireless-security.key-mgmt", "wpa-psk",
                        "802-11-wireless-security.proto", "rsn",
                        "802-11-wireless-security.psk", secret);
        break;
      case "sae":
        addCommand.push("802-11-wireless-security.key-mgmt", "sae",
                        "802-11-wireless-security.psk", secret);
        break;
      case "wep":
        addCommand.push("802-11-wireless-security.key-mgmt", "none",
                        "802-11-wireless-security.wep-key0", secret,
                        "802-11-wireless-security.wep-key-type", "key");
        break;
      default:
        addCommand.push("802-11-wireless-security.key-mgmt", "wpa-psk",
                        "802-11-wireless-security.psk", secret);
        break;
      }

      runActionSequence("connect", [
        addCommand,
        ["/usr/bin/nmcli", "connection", "up", "uuid", uuid]
      ], target);
      return;
    }

    const command = ["/usr/bin/nmcli", "device", "wifi", "connect", target];
    if (String(password || "") !== "")
      command.push("password", String(password));
    if (hidden)
      command.push("hidden", "yes");
    if (device !== "")
      command.push("ifname", device);
    runAction("connect", command, target);
  }

  function disconnect() {
    if (device === "")
      return;
    runAction("disconnect",
              ["/usr/bin/nmcli", "device", "disconnect", device],
              connectedSsid);
  }

  function forget(ssid) {
    const target = String(ssid || connectedSsid);
    if (target !== connectedSsid || connectedUuid === "")
      return;
    runAction("forget",
              ["/usr/bin/nmcli", "connection", "delete", "uuid", connectedUuid],
              target);
  }

  function runAction(kind, command, ssid) {
    runActionSequence(kind, [command], ssid);
  }

  function runActionSequence(kind, commands, ssid) {
    if (actionProcess.running || _actionSequenceActive
        || !commands || commands.length === 0)
      return;
    _actionKind = kind;
    _actionError = "";
    _actionQueue = commands.slice(1);
    _actionSequenceActive = true;
    pendingSsid = ssid;
    phase = kind === "connect" ? "connecting" : "working";
    statusText = kind === "connect"
        ? "Connecting to “" + ssid + "”…" : "Applying Wi-Fi change…";
    actionProcess.command = commands[0];
    actionProcess.running = true;
  }

  function parseNetworks(raw) {
    networks = NetworkUtils.parseNetworks(raw);
    const active = currentNetwork();
    connectedSsid = active ? active.ssid : "";
    updateBandDetails();
  }

  function updateBandDetails() {
    const current = currentNetwork();
    const frequency = current ? parseFloat(current.frequency) : 0;
    const band = NetworkUtils.bandForFrequency(frequency);
    const channel = current && current.channel !== ""
        ? current.channel : "—";
    const rate = negotiatedRate !== "—" ? negotiatedRate
        : current && current.rate !== "" ? current.rate : "—";
    details = Object.assign({}, details, {
      linkSpeed: rate,
      band: band + " / " + channel + " / " + linkWidth,
      interfaceName: device || "—"
    });
  }

  function refreshDetails() {
    if (!panelOpen || device === "")
      return;
    if (!detailQuery.running)
      detailQuery.running = true;
    if (!linkQuery.running)
      linkQuery.running = true;
  }

  Process {
    id: radioQuery
    command: ["/usr/bin/nmcli", "-t", "-f", "WIFI", "general"]
    environment: ({ "LC_ALL": "C" })
    stdout: StdioCollector {
      onStreamFinished: root.enabled = text.trim().toLowerCase() === "enabled"
    }
  }

  Process {
    id: deviceQuery
    command: ["/usr/bin/nmcli", "-t", "--escape", "yes", "-f",
              "DEVICE,TYPE,STATE,CON-UUID", "device", "status"]
    environment: ({ "LC_ALL": "C" })
    stdout: StdioCollector {
      onStreamFinished: {
        let fallback = "";
        for (const line of text.split("\n")) {
          const fields = NetworkUtils.splitNmcli(line.trim());
          if (fields.length < 3 || fields[1] !== "wifi")
            continue;
          if (fallback === "")
            fallback = fields[0];
          if (fields[2] === "connected") {
            root.device = fields[0];
            root.connectedUuid = fields[3] || "";
            root.refreshDetails();
            return;
          }
        }
        root.device = fallback;
        root.connectedUuid = "";
        root.refreshDetails();
      }
    }
  }

  Process {
    id: networkQuery
    command: ["/usr/bin/nmcli", "-t", "--escape", "yes", "-f",
              "IN-USE,SSID,SIGNAL,SECURITY,CHAN,FREQ,RATE",
              "device", "wifi", "list", "--rescan", "no"]
    environment: ({ "LC_ALL": "C" })
    stdout: StdioCollector {
      onStreamFinished: root.parseNetworks(text)
    }
  }

  Process {
    id: byteQuery
    property string sampledDevice: ""
    onStarted: sampledDevice = root.device
    command: root.device === "" ? []
        : ["/usr/bin/cat",
           "/sys/class/net/" + root.device + "/statistics/tx_bytes",
           "/sys/class/net/" + root.device + "/statistics/rx_bytes"]
    stdout: StdioCollector {
      onStreamFinished: {
        if (!root.samplingRates || byteQuery.sampledDevice !== root.device)
          return;
        const values = text.trim().split(/\s+/).map(Number);
        if (values.length < 2 || !Number.isFinite(values[0])
            || !Number.isFinite(values[1]))
          return;
        const now = Date.now();
        if (root._lastTx >= 0 && root._lastByteTime > 0) {
          const seconds = Math.max(0.05, (now - root._lastByteTime) / 1000);
          root.uploadRate = root.formatRate((values[0] - root._lastTx) / seconds);
          root.downloadRate = root.formatRate((values[1] - root._lastRx) / seconds);
        }
        root._lastTx = values[0];
        root._lastRx = values[1];
        root._lastByteTime = now;
      }
    }
  }

  Process {
    id: detailQuery
    command: root.device === "" ? []
        : ["/usr/bin/nmcli", "-t", "--escape", "yes", "-f",
           "IP4.ADDRESS,IP4.GATEWAY,IP4.DNS", "device", "show", root.device]
    environment: ({ "LC_ALL": "C" })
    stdout: StdioCollector {
      onStreamFinished: {
        let ipv4 = "—";
        let gateway = "—";
        let dns = "—";
        for (const line of text.split("\n")) {
          const split = line.indexOf(":");
          if (split < 0)
            continue;
          const key = line.slice(0, split);
          const value = line.slice(split + 1).replace(/\\:/g, ":");
          if (key.indexOf("IP4.ADDRESS") === 0 && ipv4 === "—")
            ipv4 = value.split("/")[0];
          else if (key === "IP4.GATEWAY")
            gateway = value || "—";
          else if (key.indexOf("IP4.DNS") === 0 && dns === "—")
            dns = value || "—";
        }
        root.details = Object.assign({}, root.details, {
          ipv4: ipv4,
          gateway: gateway,
          dns: dns,
          interfaceName: root.device || "—"
        });
      }
    }
  }

  Process {
    id: linkQuery
    command: root.device === "" ? []
        : ["/usr/bin/iw", "dev", root.device, "link"]
    environment: ({ "LC_ALL": "C" })
    stdout: StdioCollector {
      onStreamFinished: {
        let linkSpeed = "—";
        let width = "—";
        for (const line of text.split("\n")) {
          const trimmed = line.trim();
          if (trimmed.indexOf("rx bitrate:") === 0) {
            const value = trimmed.slice(11).trim();
            const speed = value.match(/^([0-9.]+)\s+MBit\/s/i);
            const channelWidth = value.match(/([0-9]+)MHz/i);
            if (speed)
              linkSpeed = speed[1] + " Mbit/s";
            if (channelWidth)
              width = channelWidth[1] + " MHz";
          }
        }
        root.linkWidth = width;
        root.negotiatedRate = linkSpeed;
        root.updateBandDetails();
      }
    }
  }

  Process {
    id: actionProcess
    environment: ({ "LC_ALL": "C" })
    stderr: StdioCollector {
      onStreamFinished: root._actionError = text.trim()
    }
    onExited: exitCode => {
      const success = exitCode === 0;
      if (success && root._actionQueue.length > 0) {
        const nextCommand = root._actionQueue.shift();
        root._actionError = "";
        Qt.callLater(function() {
          actionProcess.command = nextCommand;
          actionProcess.running = true;
        });
        return;
      }
      root._actionQueue = [];
      root._actionSequenceActive = false;
      root.phase = success ? "complete" : "failed";
      root.statusText = success
          ? (root._actionKind === "connect"
             ? "Connected to “" + root.pendingSsid + "”"
             : "Wi-Fi updated")
          : (root._actionError !== "" ? root._actionError
                                       : "Unable to update Wi-Fi");
      root.actionFinished(root._actionKind, success, root.statusText);
      root.refreshAll();
    }
  }

  Timer {
    interval: root.panelOpen ? 5000 : 30000
    repeat: true
    running: true
    onTriggered: root.refreshAll()
  }

  Timer {
    interval: 1000
    repeat: true
    running: root.samplingRates
    triggeredOnStart: true
    onTriggered: {
      if (!byteQuery.running)
        byteQuery.running = true;
    }
  }
}
