pragma Singleton
import QtQuick
import ".." as Shell

QtObject {
  readonly property color overlay: "#101010"
  readonly property real overlayOpacity: Shell.Theme.colors.overlayOpacity
  readonly property color card: Shell.Theme.colors.card
  readonly property color menuCard: Shell.Theme.colors.menuCard
  readonly property color menuControl: Shell.Theme.colors.menuControl
  readonly property color menuCardHover: Shell.Theme.colors.menuCardHover
  readonly property Gradient menuCardHoverGradient: Shell.Theme.colors.menuCardHoverGradient
  readonly property color menuCardBorder: Shell.Theme.colors.menuCardBorder
  readonly property color menuCardHoverBorder: Shell.Theme.colors.menuCardHoverBorder
  readonly property color trayHover: Shell.Theme.colors.trayHover
  readonly property color sessionControl: Shell.Theme.colors.sessionControl
  readonly property int sessionSize: 127
  readonly property int radius: 12
  readonly property int categoryRadius: 16
  readonly property int staggerInterval: 28
  readonly property int revealDuration: 32
  readonly property int closeDuration: 180
  readonly property int hoverDuration: 100
  readonly property int categoryHoverDuration: 250
}
