pragma Singleton
import QtQuick
import QtCore
import Quickshell
import Quickshell.Io

Singleton {
  id: root
  property string timeFormat: "12"
  readonly property bool hour24: timeFormat === "24"

  function time(date) { return Qt.formatTime(date, hour24 ? "HH:mm" : "h:mm AP"); }
  function setTimeFormat(value) {
    timeFormat = value;
    file.setText(JSON.stringify({timeFormat: timeFormat}) + "\n");
  }

  FileView {
    id: file
    path: StandardPaths.writableLocation(StandardPaths.ConfigLocation) + "/pond-interface/datetime.json"
    printErrors: false
    watchChanges: true
    onFileChanged: reload()
    onLoaded: {
      try {
        const saved = JSON.parse(text());
        if (saved.timeFormat === "12" || saved.timeFormat === "24")
          root.timeFormat = saved.timeFormat;
      } catch (e) { console.warn("Date and time format:", e); }
    }
  }
}
