pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Window
import Quickshell
import Quickshell.Wayland
import "../frontend" as Frontend

Item {
    id: root

    required property var controller
    required property var exitTransition
    property bool active: false
    property bool released: false
    property string displayName: ""
    property bool wifiConnected: false
    property list<string> presentationOutputs: []
    property var readyOutputs: ({})
    property string releasedTopology: ""
    readonly property string topology: Quickshell.screens.map(screen => screen.name).sort().join("\n")
    readonly property bool ready: active && Quickshell.screens.length > 0
        && Quickshell.screens.every(screen => readyOutputs[screen.name] === true)

    signal failed(string reason)

    onReleasedChanged: if (released) releasedTopology = topology
    onTopologyChanged: if (active && released && topology !== releasedTopology) failed("Outputs changed during unlock")
    onReadyChanged: if (active && released && !ready) failed("Unlock overlay lost its surface")

    function setReady(name, ready) {
        if (!name)
            return;
        const outputs = Object.assign({}, readyOutputs);
        if (ready) outputs[name] = true;
        else delete outputs[name];
        readyOutputs = outputs;
    }

    // Hidden overlays may not repaint, so prepare their first reveal frame up front.
    Frontend.ExitTransition {
        id: overlayExit
        exitStep: Math.max(1, root.exitTransition.exitStep)
        animationPaused: true
    }

    Variants {
        model: root.active ? Quickshell.screens : []
        delegate: PanelWindow {
            id: overlay
            required property ShellScreen modelData
            readonly property string outputName: modelData.name
            readonly property bool showPresentation: root.presentationOutputs.includes(outputName)
            readonly property int exitStep: overlayExit.exitStep
            property bool committedFrame: false
            readonly property bool ready: backingWindowVisible && width > 0 && height > 0 && committedFrame

            screen: modelData
            visible: true
            color: "transparent"
            mask: Region {}
            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "pond-lock-transition-" + outputName
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            function resetFrame() {
                committedFrame = false;
                root.setReady(outputName, false);
            }
            // Commit the first reveal frame before releasing the secure lock.
            onExitStepChanged: if (!root.released) resetFrame()
            onReadyChanged: root.setReady(outputName, ready)
            onBackingWindowVisibleChanged: if (!backingWindowVisible) resetFrame()
            onWidthChanged: resetFrame()
            onHeightChanged: resetFrame()
            Component.onCompleted: root.setReady(outputName, ready)
            Component.onDestruction: root.setReady(outputName, false)
            onResourcesLost: root.failed("Unlock overlay lost rendering resources")

            Item {
                id: content
                anchors.fill: parent
                Connections {
                    target: content.Window.window
                    function onFrameSwapped() { overlay.committedFrame = true; }
                }
                Frontend.DesktopCover {
                    anchors.fill: parent
                    exitTransition: overlayExit
                    coverColor: overlay.showPresentation ? "#1a1409" : "black"
                    background: overlay.showPresentation ? view.background : null
                }
                Frontend.Layout {
                    id: view
                    anchors.fill: parent
                    controller: root.controller
                    exitTransition: overlayExit
                    interactive: false
                    wifiConnected: root.wifiConnected
                    displayName: root.displayName
                    visible: overlay.showPresentation
                }
            }
        }
    }
}
