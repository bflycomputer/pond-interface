import QtQuick
import "." as Audio
import ".."

CardStack {
  pageComponents: ({drawer: devicesComponent})
  onPanelOpened: Audio.State.refreshPorts()

  Component { id: devicesComponent; Devices {} }
}
