import QtQuick

Item {
    id: root

    required property var authentication
    required property var transition
    required property var frontend
    property string phase: "editing"
    property bool transitionFailed: false

    signal releaseRequested
    signal finished

    function attemptUnlock(credential) {
        if (phase !== "editing")
            return;
        phase = "authenticating";
        if (!authentication.authenticate(credential))
            reject();
    }

    function reject() {
        if (phase !== "authenticating")
            return;
        phase = "editing";
        frontend.authenticationFailed();
    }

    function tryHandoff() {
        if (phase !== "waiting")
            return;
        if (transitionFailed) {
            finish();
        } else if (transition.ready) {
            handoffDeadline.stop();
            phase = "exiting";
            frontend.active = false;
            releaseRequested();
            frontend.exitTransition.animationPaused = false;
        }
    }

    function finish() {
        // Only a successful authentication may release the lock, including fallbacks.
        if (!["approving", "waiting", "exiting"].includes(phase))
            return;
        const needsRelease = phase !== "exiting";
        phase = "finished";
        successDeadline.stop();
        handoffDeadline.stop();
        transition.active = false;
        frontend.active = false;
        frontend.powerActions.cancel();
        frontend.currentText = "";
        authentication.reset();
        if (needsRelease)
            releaseRequested();
        finished();
    }

    function beginHandoff() {
        if (phase !== "approving")
            return;
        frontend.exitTransition.start();
        phase = "waiting";
        handoffDeadline.restart();
        tryHandoff();
    }

    Connections {
        target: root.frontend
        function onSubmitRequested(credential) { root.attemptUnlock(credential); }
        function onSuccessAnimationFinished() { root.beginHandoff(); }
        function onFinished() { root.finish(); }
    }
    Connections {
        target: root.authentication
        function onSucceeded() {
            if (root.phase !== "authenticating")
                return;
            root.phase = "approving";
            root.authentication.pamReady = false;
            root.transitionFailed = false;
            root.frontend.authenticationSucceeded();
            successDeadline.restart();
            root.transition.active = true;
        }
        function onRejected(result) { root.reject(); }
        function onAuthenticationError(message) {
            console.warn(message);
            root.reject();
        }
    }
    Connections {
        target: root.transition
        function onReadyChanged() { root.tryHandoff(); }
        function onFailed(reason) {
            console.warn(reason);
            root.transitionFailed = true;
            root.transition.active = false;
            if (root.phase === "waiting" || root.phase === "exiting")
                root.finish();
        }
    }
    Timer {
        id: handoffDeadline
        interval: 1000
        onTriggered: root.finish()
    }
    Timer {
        id: successDeadline
        // Bound the visual handoff after authentication, never an unanswered prompt.
        interval: 6500
        onTriggered: root.finish()
    }
}
