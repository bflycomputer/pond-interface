pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

// Shared PipeWire authority for the sidebar sound controls. The UI consumes
// real device nodes directly, so device names, selection and volume stay in
// sync with keyboard shortcuts and every other PipeWire client.
Singleton {
  id: root

  readonly property var sink: Pipewire.ready
      ? Pipewire.defaultAudioSink : null
  readonly property var source: {
    if (!Pipewire.ready)
      return null;
    const candidate = Pipewire.defaultAudioSource;
    return candidate && !candidate.isSink && candidate.audio
        ? candidate : null;
  }

  readonly property var deviceNodes: Pipewire.ready
      ? Pipewire.nodes.values.reduce(function(result, node) {
          if (!node || node.isStream)
            return result;
          const nodeName = String(node.name || "");
          const mediaName = String(node.properties
              ? node.properties["media.name"] || "" : "");
          if (nodeName === "quickshell" || mediaName === "quickshell")
            return result;
          if (node.isSink)
            result.outputs.push(node);
          else if (node.audio)
            result.inputs.push(node);
          return result;
        }, { outputs: [], inputs: [] })
      : ({ outputs: [], inputs: [] })
  readonly property var outputDevices: deviceNodes.outputs
  readonly property var inputDevices: deviceNodes.inputs

  readonly property real outputVolume: clampVolume(
      sink && sink.audio ? sink.audio.volume : 0)
  readonly property real inputVolume: clampVolume(
      source && source.audio ? source.audio.volume : 0)
  readonly property bool hasOutput: !!(sink && sink.audio)
  readonly property bool hasInput: !!(source && source.audio)

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
}
