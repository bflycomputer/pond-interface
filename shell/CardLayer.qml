import QtQuick

// Keep each page alive while scaling and clipping it behind the front card.
Item {
  id: root

  property Component cardComponent
  property var selection: ({})
  property var stackController
  property bool interactive: false
  property real backingAmount: 0

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
      color: PanelStyle.panelGradient ? "transparent" : Theme.translucent ? PanelStyle.panelSurface : Qt.rgba(
          Theme.lerp(PanelStyle.surface.r, PanelStyle.backSurface.r,
                     root.backingAmount),
          Theme.lerp(PanelStyle.surface.g, PanelStyle.backSurface.g,
                     root.backingAmount),
          Theme.lerp(PanelStyle.surface.b, PanelStyle.backSurface.b,
                     root.backingAmount),
          1)
      border.color: PanelStyle.panelBorder
      border.width: Theme.translucent ? 0 : 1
      antialiasing: true
      GradientFill { fill: PanelStyle.panelGradient }
      PanelBorder { radius: parent.radius }
    }

    Loader {
      id: cardLoader
      width: PanelStyle.width
      height: item ? item.implicitHeight : 0
      sourceComponent: root.cardComponent
      enabled: root.interactive
      scale: root.width / PanelStyle.width
      transformOrigin: Item.TopLeft

      onLoaded: {
        root.configureCard();
      }
    }

    // Hide the divider when a security menu covers the header.
    Rectangle {
      x: 19.5 * root.cardScale
      y: root.dividerY * root.cardScale
      width: 276 * root.cardScale
      height: 1
      z: 2
      visible: root.hasHeaderDivider
      color: PanelStyle.outline
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
