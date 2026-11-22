import QtQuick
import Quickshell
import "." as Polkit

// Created per request so every prompt starts from a clean state.
LazyLoader {
  id: root
  required property var screen

  active: Polkit.State.flow !== null && Polkit.State.opened
      && Polkit.State.outputName === screen.name

  Polkit.Dialog {
    screen: root.screen
    flow: Polkit.State.flow
  }
}
