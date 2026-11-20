import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pam
import Pond.System

AuthSession {
    id: root

    property bool probePamService: true
    property string pamConfig: Quickshell.env("POND_PAM_SERVICE") || "login"

    readonly property string pamConfigDirectory: "/etc/pam.d"
    backend: nativePam
    successResult: PamResult.Success
    failedResult: PamResult.Failed
    maxTriesResult: PamResult.MaxTries

    // Fingerprint runs beside the password for as long as the session is
    // locked, through its own PAM service that holds only pam_fprintd. PAM is
    // serial, so in a shared service a typed password would wait for the reader.
    property bool fingerprintWanted: false
    property bool fingerprintAvailable: false
    property bool fingerprintSuspended: false
    readonly property bool fingerprintListening: fingerprintWanted && fingerprintAvailable
        && !fingerprintSuspended
    // The service ends a round on the first finger that doesn't match. After
    // this many, or with a broken service, only the password unlocks until the
    // next lock.
    readonly property int fingerprintMaxFailures: 5
    property int fingerprintFailures: 0
    property bool fingerprintDisabled: false
    property int fingerprintErrors: 0
    property double fingerprintStarted: 0

    signal fingerprintMatched

    onFingerprintListeningChanged: {
        if (fingerprintListening) {
            fingerprintErrors = 0;
            startFingerprint();
        } else {
            stopFingerprint();
        }
    }

    function startFingerprint() {
        fingerprintRetry.stop();
        if (!fingerprintListening || fingerprintDisabled || fingerprintPam.active)
            return;
        fingerprintStarted = Date.now();
        // Refused outright means the PAM service is not installed.
        if (!fingerprintPam.start())
            fingerprintDisabled = true;
    }

    function stopFingerprint() {
        fingerprintRetry.stop();
        if (fingerprintPam.active)
            fingerprintPam.abort();
    }

    // A round that ends at once means the reader is not ready (waking up, in
    // use elsewhere): try again, less and less often.
    function retryFingerprint(failedQuickly) {
        if (!fingerprintListening)
            return;
        fingerprintErrors = failedQuickly ? fingerprintErrors + 1 : 0;
        fingerprintRetry.interval = failedQuickly
            ? Math.min(30000, 500 * Math.pow(2, fingerprintErrors)) : 300;
        fingerprintRetry.restart();
    }

    Component.onCompleted: {
        if (!probePamService)
            return;
        if (Quickshell.env("POND_PAM_SERVICE")) {
            pamReady = true;
        } else {
            detectPamServiceProc.running = true;
        }
    }

    Component.onDestruction: stopFingerprint()

    Process {
        id: detectPamServiceProc
        command: ["sh", "-c", "if [ -f /etc/pam.d/login ]; then printf '%s\\n' login; elif [ -f /etc/pam.d/system-auth ]; then printf '%s\\n' system-auth; elif [ -f /etc/pam.d/common-auth ]; then printf '%s\\n' common-auth; else exit 1; fi"]

        stdout: StdioCollector {
            onStreamFinished: {
                const service = String(text || "").trim();
                if (service.length > 0) {
                    root.pamConfig = service;
                    root.pamReady = true;
                }
            }
        }

        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0)
                root.authenticationError("No supported PAM service is available");
        }
    }

    Process {
        // Nothing to read without fprintd, a reader and an enrolled finger.
        command: ["sh", "-c", "fprintd-list \"$(id -un)\" 2>/dev/null | grep -q '^ - #'"]
        running: true
        onExited: (exitCode, exitStatus) => root.fingerprintAvailable = exitCode === 0
    }

    PamContext {
        id: nativePam
        configDirectory: root.pamConfigDirectory
        config: root.pamConfig
        // An empty user makes PamContext resolve getuid() itself. Avoid trusting
        // a mutable environment variable for the authentication identity.
        user: ""
    }

    PamContext {
        id: fingerprintPam
        configDirectory: "pam"
        config: "pond-fingerprint"
        user: ""

        onPamMessage: {
            if (!responseRequired)
                return;
            // pam_fprintd only sends notices. Never answer a prompt.
            root.fingerprintDisabled = true;
            abort();
        }

        onCompleted: result => {
            if (!root.fingerprintListening)
                return;
            if (result === PamResult.Success) {
                root.fingerprintMatched();
            } else if (result === PamResult.MaxTries) {
                root.fingerprintFailures += 1;
                root.fingerprintDisabled = root.fingerprintFailures >= root.fingerprintMaxFailures;
                root.retryFingerprint(false);
            } else {
                root.retryFingerprint(Date.now() - root.fingerprintStarted < 5000);
            }
        }
    }

    Timer {
        id: fingerprintRetry
        onTriggered: root.startFingerprint()
    }

    Logind {
        // The reader is gone during suspend: stop on the way in and start over
        // on the way out. A lock made on the way in only hears the second
        // signal, so stop there too before starting.
        onPreparingForSleepChanged: {
            root.fingerprintSuspended = true;
            root.fingerprintSuspended = preparingForSleep;
        }
    }
}
