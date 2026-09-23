pragma Singleton
import QtQuick

QtObject {
  readonly property color overlay: "#101010"
  readonly property real overlayOpacity: 0.9
  readonly property color card: "#1D1D1D"
  readonly property color hover: "#262626"
  readonly property color sessionControl: "#2C2C2C"
  readonly property int sessionSize: 127
  readonly property int radius: 12
  readonly property int staggerInterval: 28
  readonly property int revealDuration: 32
  readonly property int closeDuration: 180
  readonly property int hoverDuration: 100
}
