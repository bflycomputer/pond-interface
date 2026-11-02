pragma Singleton
import QtQuick
import ".." as Shell

QtObject {
  readonly property color overlay: "#101010"
  readonly property real overlayOpacity: Shell.Theme.colors.overlayOpacity
  readonly property color card: Shell.Theme.colors.card
  readonly property color sessionControl: Shell.Theme.colors.sessionControl
  readonly property int sessionSize: 127
  readonly property int radius: 12
  readonly property int staggerInterval: 28
  readonly property int revealDuration: 32
  readonly property int closeDuration: 180
  readonly property int hoverDuration: 100
}
