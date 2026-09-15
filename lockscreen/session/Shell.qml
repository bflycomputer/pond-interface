pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import Pond.System

ShellRoot {
    id: root

    readonly property Session session: locker.item as Session

    function lock() { locker.active = true; }
    function lockAndSuspend() {
        lock();
        suspendWait.checks = 0;
        suspendWait.restart();
    }
    Component.onCompleted: {
        // Reloading a secure lock must never destroy its authentication state.
        Quickshell.watchFiles = false;
        if (Quickshell.env("POND_LOCK_NO_START") !== "1")
            lock();
    }

    SessionInfo { id: info }
    NetworkStatus { id: network }
    QtObject {
        id: power
        function shutdown() { Quickshell.execDetached(["/usr/bin/systemctl", "poweroff"]); }
        function reboot() { Quickshell.execDetached(["/usr/bin/systemctl", "reboot"]); }
        function suspend() { Quickshell.execDetached(["/usr/bin/systemctl", "suspend"]); }
    }
    Loader {
        id: locker
        active: false
        sourceComponent: Session {
            displayName: info.displayName
            wifiConnected: network.wifiConnected
            powerBackend: power
            presentationOutputs: (Quickshell.env("POND_LOCK_OUTPUTS") || "").split(",").filter(name => name.length > 0)
            onFinished: locker.active = false
        }
    }
    Timer {
        id: suspendWait
        property int checks: 0
        interval: 100
        repeat: true
        onTriggered: {
            if (root.session && root.session.secure) {
                stop();
                power.suspend();
            } else if (++checks > 30) {
                stop();
                console.warn("Session lock was not confirmed; refusing to suspend");
            }
        }
    }
    IpcHandler {
        target: "lockscreen"
        function lock(): void { root.lock(); }
        function lockAndSuspend(): void { root.lockAndSuspend(); }
        function isLocked(): bool { return locker.active; }
        function isSecure(): bool { return root.session !== null && root.session.secure; }
    }
}
