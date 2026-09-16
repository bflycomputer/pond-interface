pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth
import Quickshell.Services.UPower
import "Devices.js" as DeviceUtils

Singleton {
  id: root
  readonly property var adapter: Bluetooth.defaultAdapter
  readonly property bool available: adapter !== null
  readonly property bool enabled: !!adapter && adapter.enabled
  readonly property bool blocked: !!adapter && adapter.state === BluetoothAdapterState.Blocked
  readonly property bool discovering: !!adapter && adapter.discovering
  property bool panelOpen: false
  property bool transportReady: false
  property int serial: 0
  property var pending: ({})
  property var failures: ({})
  property var prompt: ({kind: ""})
  property string errorText: ""
  property var discoveryConsumers: []
  property string discoveryPath: ""
  property bool discoveryPending: false
  property bool discoveryOwned: false
  readonly property bool scanningRequested: discoveryConsumers.length > 0
  readonly property bool powerBusy: Object.keys(pending).some(key => pending[key].action === "power")
  readonly property var devices: {
    const values = adapter ? adapter.devices.values : [];
    return values.map(device => {
      const power = DeviceUtils.powerDeviceFor(device.address, UPower.devices.values);
      return ({
      path: device.dbusPath, address: device.address,
      name: device.name || device.deviceName || device.address,
      deviceName: device.deviceName, icon: DeviceUtils.classifier(device.icon),
      type: DeviceUtils.typeLabel(device.icon), connected: device.connected,
      paired: device.paired, bonded: device.bonded, trusted: device.trusted,
      blocked: device.blocked, battery: DeviceUtils.batteryPercent(device, power),
      model: power ? power.model : "",
      nativeBusy: device.pairing || device.state === BluetoothDeviceState.Connecting
          || device.state === BluetoothDeviceState.Disconnecting,
      adapterName: device.adapter ? device.adapter.name : ""
    }); }).sort((a, b) => Number(b.connected) - Number(a.connected)
        || a.name.localeCompare(b.name));
  }
  readonly property var pairedDevices: devices.filter(d => d.paired || d.bonded || d.connected)
  readonly property var nearbyDevices: devices.filter(d => (!d.paired && !d.bonded) || isBusy(d.path))
  signal panelCommand(string command, string outputName)
  signal actionFinished(string path, string action, bool success)

  function requestPanel(command, outputName) { panelCommand(command, outputName || ""); }
  function deviceFor(path) { return devices.find(d => d.path === path) || null; }
  function isBusy(path) {
    return Object.keys(pending).some(key => pending[key].path === path);
  }
  function failed(path) { return failures[path] !== undefined; }
  function send(action, path, extra) {
    if (!transportReady) { errorText = "Bluetooth service is starting. Try again."; return false; }
    const job = Object.assign({id: ++serial, action: action, path: path}, extra || {});
    const next = Object.assign({}, pending); next[job.id] = job; pending = next;
    const errors = Object.assign({}, failures); delete errors[path]; failures = errors;
    errorText = "";
    actions.write(JSON.stringify(job) + "\n");
    return true;
  }
  function activate(device) {
    if (!device || !enabled || isBusy(device.path)) return;
    if (device.blocked) { errorText = "This device is blocked in Bluetooth settings."; return; }
    send(device.connected ? "disconnect" : device.paired || device.bonded ? "connect" : "pair", device.path);
  }
  function forget(device) {
    if (device && !isBusy(device.path)) send("forget", device.path);
  }
  function setEnabled(value) {
    if (adapter && !powerBusy) send("power", adapter.dbusPath, {enabled: value});
  }
  function answer(accept, value) {
    if (transportReady) actions.write(JSON.stringify({action: "answer", promptId: prompt.id,
        accept: accept, value: value || ""}) + "\n");
  }
  function cancelPairing() {
    if (transportReady) actions.write(JSON.stringify({action: "cancel"}) + "\n");
    prompt = {kind: ""};
  }
  function setDiscoveryConsumer(owner, active) {
    const next = discoveryConsumers.filter(value => value !== owner);
    if (active) next.push(owner);
    discoveryConsumers = next;
    syncDiscovery();
  }
  function syncDiscovery() {
    if (!transportReady || discoveryPending) return;
    const path = enabled && adapter ? adapter.dbusPath : "";
    if (discoveryOwned && (!scanningRequested || path !== discoveryPath)) {
      discoveryPending = true;
      send("scan-stop", discoveryPath);
    } else if (scanningRequested && path !== "" && !discoveryOwned) {
      discoveryPath = path;
      discoveryPending = true;
      send("scan-start", path);
    }
  }
  onEnabledChanged: syncDiscovery()
  onAdapterChanged: syncDiscovery()
  onTransportReadyChanged: if (transportReady) syncDiscovery()

  function receive(message) {
    if (message.event === "ready") { transportReady = true; return; }
    if (message.event === "prompt") { prompt = message; return; }
    if (message.event === "error") { errorText = message.error; return; }
    if (message.event !== "result") return;
    const job = pending[message.id];
    if (!job) return;
    const next = Object.assign({}, pending); delete next[message.id]; pending = next;
    if (job.action === "scan-start" || job.action === "scan-stop") {
      discoveryPending = false;
      discoveryOwned = job.action === "scan-start" && message.success;
      if (!discoveryOwned) discoveryPath = "";
      if (!message.success && job.action === "scan-start")
        errorText = "Couldn’t search for nearby devices. Close and reopen search to try again.";
      else Qt.callLater(syncDiscovery);
    } else if (!message.success) {
      const errors = Object.assign({}, failures); errors[job.path] = Date.now() + 3500; failures = errors;
      errorText = job.action === "power" ? "Couldn’t change Bluetooth power. Check the adapter or airplane mode."
          : job.action === "forget" ? "Couldn’t forget this device. Try again."
          : job.action === "disconnect" ? "Couldn’t disconnect. Try again."
          : "Couldn’t connect. Make sure the device is on and nearby, then try again.";
    }
    actionFinished(job.path, job.action, message.success);
  }

  Process {
    id: actions
    command: ["python3", Quickshell.shellDir + "/bluetooth/actions.py"]
    running: true
    stdinEnabled: true
    stdout: SplitParser {
      onRead: line => {
        try { root.receive(JSON.parse(line)); }
        catch (error) { console.warn("Bluetooth response:", error); }
      }
    }
    onExited: {
      root.transportReady = false;
      root.pending = ({});
      root.prompt = {kind: ""};
      root.discoveryPending = false;
      root.discoveryOwned = false;
      root.discoveryPath = "";
      restartDelay.restart();
    }
  }
  Timer { id: restartDelay; interval: 2000; onTriggered: actions.running = true }
  Timer {
    interval: 250; running: Object.keys(root.failures).length > 0; repeat: true
    onTriggered: {
      const now = Date.now(); const remaining = {};
      for (const path of Object.keys(root.failures))
        if (root.failures[path] > now) remaining[path] = root.failures[path];
      root.failures = remaining;
    }
  }
}
