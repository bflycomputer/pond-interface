import QtQuick
import "." as Audio
import ".."

CardStack {
  pageComponents: ({drawer: devicesComponent, mixer: mixerComponent})
  onPanelOpened: Audio.State.refreshPorts()

  Component { id: devicesComponent; Devices {} }
  Component { id: mixerComponent; Mixer {} }
}
