import QtQuick

Item {
    id: root

    signal succeeded
    signal rejected(int result)
    signal authenticationError(string message)

    property bool authenticationPending: false
    property bool pamReady: false
    property var backend: null
    property int successResult: 0
    property int failedResult: 1
    property int maxTriesResult: 3

    property string _pendingCredential: ""
    property bool _terminalHandled: false
    property string _backendErrorMessage: ""

    width: 0
    height: 0
    visible: false

    function clearPendingCredential() {
        _pendingCredential = "";
    }

    function reset() {
        _terminalHandled = true;
        authenticationPending = false;
        if (backend && backend.active)
            backend.abort();
        _backendErrorMessage = "";
        clearPendingCredential();
    }

    function authenticate(credential) {
        if (!pamReady || authenticationPending || !backend || backend.active)
            return false;

        const snapshot = String(credential || "");
        if (snapshot.length === 0)
            return false;

        _pendingCredential = snapshot;
        _terminalHandled = false;
        _backendErrorMessage = "";
        authenticationPending = true;

        if (!backend.start()) {
            finishWithError(qsTrId("pond.unable_to_start_the_authentication_service"));
            return false;
        }
        return true;
    }

    function finishWithError(message) {
        if (_terminalHandled)
            return;
        _terminalHandled = true;
        authenticationPending = false;
        clearPendingCredential();
        authenticationError(message || qsTrId("pond.authentication_service_error"));
    }

    function handlePamMessage() {
        if (!backend || !backend.responseRequired)
            return;
        if (_pendingCredential.length === 0) {
            if (backend.active)
                backend.abort();
            finishWithError(qsTrId("pond.authentication_requested_an_unexpected_response"));
            return;
        }
        backend.respond(_pendingCredential);
    }

    function handleCompleted(result) {
        if (!authenticationPending || _terminalHandled)
            return;

        _terminalHandled = true;
        authenticationPending = false;
        clearPendingCredential();

        if (result === successResult) {
            succeeded();
        } else if (result === failedResult || result === maxTriesResult) {
            rejected(result);
        } else {
            authenticationError(_backendErrorMessage || qsTrId("pond.authentication_service_error"));
        }
    }

    Component.onDestruction: reset()

    Connections {
        target: root.backend

        function onPamMessage() {
            root.handlePamMessage();
        }

        function onError(error) {
            root._backendErrorMessage = root.backend && root.backend.message
                ? String(root.backend.message)
                : qsTrId("pond.authentication_service_error");
        }

        function onCompleted(result) {
            root.handleCompleted(result);
        }
    }
}
