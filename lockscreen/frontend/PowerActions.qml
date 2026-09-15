import QtQuick

Item {
    id: root
    required property var backend
    property bool countdownEnabled: true
    property int countdownDuration: 10000
    property bool active: false
    property int remaining: 0
    property string action: "shutdown"

    function request(requestedAction) {
        if (requestedAction !== "shutdown" && requestedAction !== "restart") return;
        if (!countdownEnabled || (active && action === requestedAction)) {
            execute(requestedAction);
            return;
        }
        // Changing the chosen action starts a fresh countdown, never confirms
        // the previously selected action accidentally.
        cancel();
        action = requestedAction;
        remaining = Math.max(100, countdownDuration);
        active = true;
        countdown.start();
    }
    function cancel() {
        countdown.stop();
        active = false;
        remaining = 0;
    }
    function execute(requestedAction) {
        cancel();
        if (requestedAction === "restart") backend.reboot();
        else if (requestedAction === "shutdown") backend.shutdown();
    }
    Timer {
        id: countdown
        interval: 100
        repeat: true
        onTriggered: {
            root.remaining -= interval;
            if (root.remaining <= 0) root.execute(root.action);
        }
    }
}
