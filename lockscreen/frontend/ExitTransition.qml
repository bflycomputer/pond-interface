import QtQuick

Item {
    id: root

    property int exitStep: 0
    property real speed: 1.0
    property bool animationPaused: false

    readonly property bool running: exitStep >= 1 && exitStep <= 4
    readonly property bool complete: exitStep > 4
    readonly property int revealedQuadrantCount: Math.min(4, exitStep)
    readonly property bool peripheryVisible: exitStep <= 1
    readonly property bool moonVisible: exitStep <= 2

    signal started
    signal finished

    function start() {
        exitStep = 1;
        started();
    }

    function reset() {
        exitStep = 0;
    }

    function stepAnimation() {
        if (!running)
            return;
        // Hold the fourth step for a full tick before completing the exit.
        exitStep++;
        if (complete)
            finished();
    }

    Timer {
        interval: Math.max(16, 170 / root.speed)
        running: root.running && !root.animationPaused
        repeat: true
        onTriggered: root.stepAnimation()
    }
}
