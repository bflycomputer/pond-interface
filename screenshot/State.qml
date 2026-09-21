pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
  id: root
  property string imageSource: ""
  property string outputName: ""
  property int generation: 0
  property bool copied: false
  property bool dragging: false
  readonly property string helper: decodeURIComponent(Qt.resolvedUrl("clipboard.py").toString().replace(/^file:\/\//, ""))

  function receive(path, output) {
    copied = false;
    if (!dragging) dismissTimer.restart();
    const reader = readerComponent.createObject(root, {
      captureGeneration: ++generation,
      captureOutput: output || Quickshell.screens[0]?.name || "",
      command: ["python3", helper, "read", path || ""]
    });
    reader.running = true;
  }

  function dismiss() {
    dismissTimer.stop();
    ++generation;
    imageSource = "";
    copied = false;
  }

  function copy() {
    if (!imageSource || copier.running) return;
    copier.captureGeneration = generation;
    copier.payload = imageSource.substring("data:image/png;base64,".length);
    copier.stdinEnabled = true;
    copier.running = true;
  }

  onDraggingChanged: {
    if (dragging) dismissTimer.stop();
    else if (imageSource) dismissTimer.restart();
  }

  Component {
    id: readerComponent
    Process {
      id: reader
      required property int captureGeneration
      required property string captureOutput
      property string payload: ""
      stdout: StdioCollector { onStreamFinished: reader.payload = text.trim() }
      stderr: StdioCollector { onStreamFinished: if (text.trim()) console.warn(text.trim()) }
      onExited: code => {
        if (captureGeneration === root.generation && code === 0 && payload) {
          root.outputName = captureOutput;
          root.imageSource = "data:image/png;base64," + payload;
          root.copied = true;
          copyTag.restart();
          if (!root.dragging) dismissTimer.restart();
        }
        destroy();
      }
    }
  }

  Process {
    id: copier
    property int captureGeneration
    property string payload
    command: ["python3", root.helper, "copy"]
    onStarted: { write(payload); stdinEnabled = false; payload = ""; }
    stderr: StdioCollector { onStreamFinished: if (text.trim()) console.warn(text.trim()) }
    onExited: code => {
      if (code === 0 && captureGeneration === root.generation) {
        root.copied = true;
        copyTag.restart();
      }
    }
  }

  Timer {
    id: dismissTimer
    interval: 30000
    onTriggered: root.dismiss()
  }

  Timer {
    id: copyTag
    interval: 2000
    onTriggered: root.copied = false
  }
}
