import QtQuick
import "GridState.js" as GridState

Item {
    id: root

    objectName: "animationController"

    property real speed: 1.0
    property bool animationPaused: false
    property bool authResultHandled: false
    property var animationState: GridState.createState(Date.now())

    readonly property int visibleCellCount: GridState.visibleCellCount(animationState.inputLength)
    readonly property string animationPhase: animationState.animationPhase
    readonly property bool acceptingInput: GridState.acceptsInput(animationState)

    signal successAnimationFinished
    signal errorAnimationFinished

    function dispatch(event) {
        const previousPhase = animationState.animationPhase;
        const next = GridState.reduce(animationState, event);
        if (next === animationState)
            return;
        animationState = next;

        if (previousPhase !== "succeeded" && animationState.animationPhase === "succeeded")
            successAnimationFinished();
        if (previousPhase === "errorCenter" && animationState.animationPhase === "idle")
            errorAnimationFinished();
    }

    function reset() {
        authResultHandled = false;
        dispatch({ type: "RESET", seed: Date.now() });
    }

    function syncLength(inputLength) {
        dispatch({ type: "SYNC_LENGTH", length: inputLength });
    }

    function beginAuthentication(inputLength) {
        authResultHandled = false;
        dispatch({ type: "AUTH_START", length: inputLength });
    }

    function authenticationFailed() {
        if (authResultHandled)
            return false;
        authResultHandled = true;
        dispatch({ type: "AUTH_FAILED" });
        return true;
    }

    function authenticationSucceeded() {
        if (authResultHandled)
            return false;
        authResultHandled = true;
        dispatch({ type: "AUTH_SUCCEEDED" });
        return true;
    }

    function stepAnimation() {
        if (GridState.isAnimating(animationState))
            dispatch({ type: "ANIMATION_TICK" });
    }

    function cellVisual(cellIndex, exitStep = 0) {
        return GridState.cellVisual(animationState, cellIndex, exitStep);
    }

    Timer {
        interval: 360
        repeat: true
        running: !root.animationPaused && root.animationPhase === "idle"
        onTriggered: root.dispatch({ type: "IDLE_TICK" })
    }

    Timer {
        interval: 520
        repeat: true
        running: !root.animationPaused && (root.animationPhase === "idle" || root.animationPhase === "typing")
        onTriggered: root.dispatch({ type: "BLINK" })
    }

    Timer {
        interval: Math.max(16, GridState.animationIntervalMs(root.animationState) / root.speed)
        repeat: true
        running: !root.animationPaused && GridState.isAnimating(root.animationState)
        onTriggered: root.dispatch({ type: "ANIMATION_TICK" })
    }
}
