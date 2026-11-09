pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

// Shared PipeWire authority for the sidebar sound controls. The UI consumes
// real device nodes directly, so device names, selection and volume stay in
// sync with keyboard shortcuts and every other PipeWire client.
Singleton {
  id: root

  readonly property var sink: Pipewire.ready
      ? Pipewire.defaultAudioSink : null
  readonly property var source: Pipewire.ready ? Pipewire.defaultAudioSource : null
  readonly property var deviceNodes: Pipewire.ready ? Pipewire.nodes.values.filter(node =>
      !node.isStream && node.name !== "quickshell" && node.properties["media.name"] !== "quickshell") : []
  readonly property var outputDevices: deviceNodes.filter(node =>
      node.isSink && !unpluggedDevices[node.name])
  readonly property var inputDevices: deviceNodes.filter(node =>
      !node.isSink && node.audio && !unpluggedDevices[node.name])

  // Per-application streams, read straight from PipeWire like the devices.
  // Monitoring streams (peak meters, the shell's own) are not apps.
  readonly property var streamNodes: Pipewire.ready ? Pipewire.nodes.values.filter(node =>
      node.isStream && node.audio && node.name !== "quickshell"
      && node.properties["media.name"] !== "quickshell"
      && node.properties["stream.monitor"] !== "true") : []
  readonly property var playbackStreams: streamNodes.filter(node =>
      node.properties["media.class"] === "Stream/Output/Audio")
  readonly property var recordingStreams: streamNodes.filter(node =>
      node.properties["media.class"] === "Stream/Input/Audio")

  readonly property real outputVolume: clampVolume(
      sink && sink.audio ? sink.audio.volume : 0)
  readonly property real inputVolume: clampVolume(
      source && source.audio ? source.audio.volume : 0)
  readonly property bool hasOutput: !!(sink && sink.audio)
  readonly property bool hasInput: !!(source && source.audio)
  readonly property bool outputMuted: hasOutput && sink.audio.muted

  property var unpluggedDevices: ({})
  property int observedSinkId: -1
  property double suppressExternalUntil: 0

  signal keyboardOutputVolumeChanged(real value)

  function clampVolume(value) {
    const numeric = Number(value);
    if (!isFinite(numeric))
      return 0;
    return Math.max(0, Math.min(1, numeric));
  }

  function displayName(node) {
    if (!node)
      return "Unknown device";
    return String(node.description || node.nickname || node.name
                  || "Unknown device");
  }

  function appName(node) {
    if (!node)
      return "Unknown app";
    const props = node.properties || {};
    return String(props["application.name"] || node.description
                  || node.nickname || node.name || "Unknown app");
  }

  function streamTitle(node) {
    if (!node)
      return "";
    const title = String((node.properties || {})["media.name"] || "");
    return title === appName(node) ? "" : title;
  }

  function streamVolume(node) {
    return clampVolume(node && node.audio ? node.audio.volume : 0);
  }

  function setStreamVolume(node, value) {
    if (!node || !node.audio)
      return;
    node.audio.muted = false;
    node.audio.volume = clampVolume(value);
  }

  function toggleStreamMute(node) {
    if (node && node.audio)
      node.audio.muted = !node.audio.muted;
  }

  function suppressExternalChanges(duration) {
    suppressExternalUntil = Math.max(
        suppressExternalUntil, Date.now() + (duration || 300));
  }

  function setOutputVolume(value) {
    if (!hasOutput)
      return;
    suppressExternalChanges(350);
    sink.audio.muted = false;
    sink.audio.volume = clampVolume(value);
  }

  function setInputVolume(value) {
    if (!hasInput)
      return;
    source.audio.muted = false;
    source.audio.volume = clampVolume(value);
  }

  function adjustOutputVolume(delta) {
    if (!hasOutput) return;
    setOutputVolume(outputVolume + delta);
    keyboardOutputVolumeChanged(outputVolume);
  }

  function toggleOutputMute() {
    if (!hasOutput) return;
    sink.audio.muted = !sink.audio.muted;
    keyboardOutputVolumeChanged(outputVolume);
  }

  function toggleInputMute() {
    if (hasInput) source.audio.muted = !source.audio.muted;
  }

  function setOutputDevice(node) {
    if (!node || !Pipewire.ready)
      return;
    suppressExternalChanges(500);
    Pipewire.preferredDefaultAudioSink = node;
  }

  function setInputDevice(node) {
    if (!node || !Pipewire.ready)
      return;
    Pipewire.preferredDefaultAudioSource = node;
  }

  function refreshPorts() {
    portQuery.running = true;
  }

  function receivePorts(text) {
    const server = JSON.parse(text);
    const unplugged = {};
    for (const device of server.sinks.concat(server.sources)) {
      if (device.ports.length > 0 && device.ports.every(
          port => port.availability === "not available"))
        unplugged[device.name] = true;
    }
    unpluggedDevices = unplugged;
  }

  onOutputVolumeChanged: {
    const currentSinkId = sink ? Number(sink.id) : -1;
    if (currentSinkId !== observedSinkId) {
      observedSinkId = currentSinkId;
      return;
    }
    if (Date.now() >= suppressExternalUntil)
      keyboardOutputVolumeChanged(outputVolume);
  }

  Connections {
    target: Pipewire
    function onDefaultAudioSinkChanged() {
      root.suppressExternalChanges(500);
      root.observedSinkId = root.sink ? Number(root.sink.id) : -1;
    }
  }

  PwObjectTracker { objects: [root.sink, root.source].filter(node => node !== null) }
  // Bind app streams only while the mixer is open; volume is unavailable otherwise.
  property bool streamsTracked: false
  PwObjectTracker { objects: root.streamsTracked ? root.streamNodes : [] }

  // Which device a stream is attached to, and how to send it elsewhere. The
  // QML bindings expose links read-only, so the move goes through pactl,
  // which addresses streams by their object.serial.
  function streamDevice(node) {
    if (!node || !Pipewire.ready)
      return null;
    const id = Number(node.id);
    const group = Pipewire.linkGroups.values.find(link => link.source && link.target
        && (Number(link.source.id) === id || Number(link.target.id) === id));
    if (!group)
      return null;
    return Number(group.source.id) === id ? group.target : group.source;
  }

  function moveStream(node, device) {
    const serial = node && node.properties ? node.properties["object.serial"] : undefined;
    if (serial === undefined || !device)
      return;
    moveStreamProcess.command = ["pactl",
        node.properties["media.class"] === "Stream/Input/Audio"
            ? "move-source-output" : "move-sink-input",
        String(serial), String(device.name)];
    moveStreamProcess.running = true;
  }

  Process { id: moveStreamProcess }

  Process {
    id: portQuery
    command: ["pactl", "-f", "json", "list"]
    environment: ({ "LC_ALL": "C" })
    running: true
    stdout: StdioCollector { onStreamFinished: root.receivePorts(text) }
  }
}
