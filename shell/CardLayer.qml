import QtQuick

// One persistent card instance in the stack. The stack changes
// only this wrapper's geometry and reveal values, so a card keeps its own form
// state while moving between front, back, hidden, and front again.
Item {
  id: root

  property Component cardComponent
  property var selection: ({})
  property var stackController
  property bool interactive: false
  property real backingAmount: 0
  property real cardOpacity: 1

  readonly property real naturalHeight: cardLoader.item
      ? cardLoader.item.implicitHeight : 0
  readonly property bool ready: cardLoader.status === Loader.Ready
  readonly property real cardScale: width / PanelStyle.width
  readonly property real dividerY: cardLoader.item?.headerDividerY ?? 59.5
  readonly property bool hasHeaderDivider: cardLoader.item?.headerDividerVisible ?? true

  clip: false

  Shadow {
    anchors.fill: parent
    cornerRadius: Theme.lerp(PanelStyle.radius, 14.38,
                             root.backingAmount)
    shadows: PanelStyle.frontShadows
    visible: opacity > 0.001
    opacity: 1 - root.backingAmount
  }

  Shadow {
    anchors.fill: parent
    cornerRadius: Theme.lerp(PanelStyle.radius, 14.38,
                             root.backingAmount)
    shadows: PanelStyle.backShadows
    visible: opacity > 0.001
    opacity: root.backingAmount
  }

  Item {
    anchors.fill: parent
    clip: true

    Rectangle {
      anchors.fill: parent
      radius: Theme.lerp(PanelStyle.radius, 14.38,
                         root.backingAmount)
      color: Qt.rgba(
          Theme.lerp(PanelStyle.surface.r, PanelStyle.backSurface.r,
                     root.backingAmount),
          Theme.lerp(PanelStyle.surface.g, PanelStyle.backSurface.g,
                     root.backingAmount),
          Theme.lerp(PanelStyle.surface.b, PanelStyle.backSurface.b,
                     root.backingAmount),
          1)
      border.color: PanelStyle.border
      border.width: 0.5
      antialiasing: true
    }

    Loader {
      id: cardLoader
      width: PanelStyle.width
      height: item ? item.implicitHeight : 0
      sourceComponent: root.cardComponent
      opacity: root.cardOpacity
      scale: root.width / PanelStyle.width
      transformOrigin: Item.TopLeft

      onLoaded: {
        root.configureCard();
      }
    }

    // The divider is part of the card shell, so it remains visible while the
    // card content fades between its front and backing presentations. Hide it
    // when the security menu covers the header inside the loaded card.
    Rectangle {
      x: 19.5 * root.cardScale
      y: root.dividerY * root.cardScale
      width: 276 * root.cardScale
      height: 1
      z: 2
      visible: root.hasHeaderDivider
      color: PanelStyle.border
      antialiasing: false
    }
  }

  onSelectionChanged: configureCard()
  onInteractiveChanged: configureCard()

  function configureCard() {
    const item = cardLoader.item;
    if (!item)
      return;
    item.stackController = root.stackController;
    item.interactive = root.interactive;
    if ("selection" in item)
      item.selection = root.selection || ({});
  }

}
