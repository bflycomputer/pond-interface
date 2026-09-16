pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Networking

// Network objects update through NetworkManager signals. Commands remain for
// operations requiring completion/error replies and details absent from the API.
Singleton {
  id: root

  readonly property bool enabled: Networking.wifiEnabled
  readonly property var adapters: Networking.devices.values.filter(d => d.type === DeviceType.Wifi)
  readonly property var adapter: adapters.find(d => d.connected) || adapters[0] || null
  readonly property string device: adapter ? adapter.name : ""
  readonly property string connectedSsid: networks.find(n => n.connected)?.ssid || ""
  property string connectedUuid: ""
  readonly property var networks: (adapter ? adapter.networks.values : [])
      .filter(n => n.connected || n.signalStrength > 0)
      .map(n => ({ssid: n.name, signal: n.signalStrength * 100,
                 bars: n.signalStrength >= 0.6 ? 3 : n.signalStrength >= 0.35 ? 2 : 1,
                 locked: n.security !== WifiSecurityType.Open, connected: n.connected}))
      .sort((a, b) => Number(b.connected) - Number(a.connected)
          || b.signal - a.signal || a.ssid.localeCompare(b.ssid))
  property string uploadRate: "0KB"
  property string downloadRate: "0KB"
  property string phase: "idle"
  property string statusText: ""
  property string pendingSsid: ""
  property bool panelOpen: false
  property var rateConsumers: []
  readonly property bool ratesRequested: panelOpen || rateConsumers.length > 0
  readonly property bool samplingRates: ratesRequested && device !== ""
  property string linkSpeed: "—"
  property string band: "—"
  property string ipv4: "—"
  property string gateway: "—"
  property string dns: "—"

  property real _lastTx: -1
  property real _lastRx: -1
  property double _lastByteTime: 0
  property string _actionKind: ""
  property string _actionError: ""
  property var _actionQueue: []
  property bool _actionSequenceActive: false

  signal actionFinished(string kind, bool success, string message)

  Binding {
    target: root.adapter
    property: "scannerEnabled"
    value: root.panelOpen
    when: root.adapter !== null
    restoreMode: Binding.RestoreBindingOrValue
  }

  onPanelOpenChanged: refreshDetails()
  onConnectedSsidChanged: {
    connectedUuid = "";
    linkSpeed = band = ipv4 = gateway = dns = "—";
    refreshDetails();
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
    connectedUuid = "";
    linkSpeed = band = "—";
    ipv4 = gateway = dns = "—";
    refreshDetails();
  }

  function resetRates() {
    _lastTx = -1;
    _lastRx = -1;
    _lastByteTime = 0;
    uploadRate = "0B";
    downloadRate = "0B";
  }

  function formatRate(bytesPerSecond) {
    const value = Math.max(0, Number(bytesPerSecond) || 0);
    if (value >= 1048576)
      return (value / 1048576).toFixed(value >= 10485760 ? 0 : 1) + "MB";
    if (value >= 1024)
      return (value / 1024).toFixed(value >= 10240 ? 0 : 1) + "KB";
    return Math.round(value) + "B";
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

  function refreshDetails() {
    if (!panelOpen || device === "")
      return;
    detailQuery.running = true;
    linkQuery.running = true;
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
        : ["/usr/bin/nmcli", "--escape", "no", "-g",
           "IP4.ADDRESS,IP4.GATEWAY,IP4.DNS,GENERAL.CON-UUID", "device", "show", root.device]
    environment: ({ "LC_ALL": "C" })
    stdout: StdioCollector {
      onStreamFinished: {
        const [address = "", gateway = "", dns = "", uuid = ""] = text.split("\n");
        root.connectedUuid = uuid === "--" ? "" : uuid;
        root.ipv4 = address.split(" | ")[0].split("/")[0] || "—";
        root.gateway = gateway || "—";
        root.dns = dns.split(" | ")[0] || "—";
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
        let frequency = 0;
        for (const line of text.split("\n")) {
          const trimmed = line.trim();
          if (trimmed.startsWith("freq:")) frequency = Number(trimmed.slice(5));
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
        root.linkSpeed = linkSpeed;
        const band = frequency >= 5925 ? "6 GHz" : frequency >= 4900 ? "5 GHz"
            : frequency >= 2400 ? "2.4 GHz" : "—";
        const channel = frequency === 2484 ? 14 : frequency === 5935 ? 2
            : frequency >= 5950 ? (frequency - 5950) / 5
            : frequency >= 5000 ? (frequency - 5000) / 5
            : frequency >= 4910 ? (frequency - 4000) / 5
            : frequency >= 2400 ? (frequency - 2407) / 5 : "—";
        root.band = band + " / " + channel + " / " + width;
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
      root.refreshDetails();
    }
  }

  Timer {
    interval: 5000
    repeat: true
    running: root.panelOpen
    onTriggered: root.refreshDetails()
  }

  Timer {
    interval: 1000
    repeat: true
    running: root.samplingRates
    triggeredOnStart: true
    onTriggered: {
      byteQuery.running = true;
    }
  }
}
