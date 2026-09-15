import QtQuick
import "form" as Form

Item {
    id: root

    required property var powerBackend
    property string currentText: ""
    property bool authenticationPending: false
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
        if (!acceptingInput || !currentText.length)
            return;
        const credential = currentText;
        authenticationPending = true;
        grid.beginAuthentication(credential.length);
        currentText = "";
        submitRequested(credential);
    }

    function resetInput() {
        currentText = "";
        grid.reset();
        authenticationPending = false;
        inputReset();
        if (!inputBlocked)
            refocusRequested();
    }

    function authenticationFailed() {
        grid.authenticationFailed();
    }

    function authenticationSucceeded() {
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
