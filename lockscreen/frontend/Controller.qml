import QtQuick
import "form" as Form

Item {
    id: root

    required property var powerBackend
    property string currentText: ""
    property bool authenticationPending: false
    property bool resultPending: false
    property bool inputBlocked: false
    property bool active: true
    readonly property bool acceptingInput: active && !authenticationPending && !inputBlocked && grid.acceptingInput
    property alias controller: grid
    property alias exitTransition: exit

    signal submitRequested(string credential)
    signal successAnimationFinished
    signal finished
    signal refocusRequested
    signal inputReset

    function submit() {
        if (!acceptingInput || resultPending || !currentText.length)
            return;
        const credential = currentText;
        authenticationPending = true;
        resultPending = true;
        presumedRejection.restart();
        grid.beginAuthentication(credential.length);
        currentText = "";
        submitRequested(credential);
    }

    function resetInput() {
        currentText = "";
        resultPending = false;
        grid.reset();
        authenticationPending = false;
        inputReset();
        if (!inputBlocked)
            refocusRequested();
    }

    function authenticationFailed() {
        resultPending = false;
        grid.authenticationFailed();
    }

    function authenticationSucceeded() {
        if (resultPending)
            grid.authResultHandled = false;
        resultPending = false;
        grid.authenticationSucceeded();
    }

    function requestPower(action) {
        if (!active)
            return;
        if (action === "shutdown")
            powerBackend.shutdown();
        else if (action === "restart")
            powerBackend.reboot();
    }

    Timer {
        id: presumedRejection
        // Success answers in ~0.1s; PAM holds a failure back for 1-3s.
        interval: 500
        onTriggered: if (root.resultPending) grid.authenticationFailed()
    }
    Form.AnimationController {
        id: grid
        onSuccessAnimationFinished: root.successAnimationFinished()
        onErrorAnimationFinished: {
            root.authenticationPending = false;
            if (!root.inputBlocked)
                root.refocusRequested();
        }
    }
    ExitTransition {
        id: exit
        animationPaused: true
        onFinished: root.finished()
    }
}
