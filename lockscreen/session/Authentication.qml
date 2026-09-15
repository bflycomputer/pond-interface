import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pam

AuthSession {
    id: root

    property bool probePamService: true
    property string pamConfig: Quickshell.env("POND_PAM_SERVICE") || "login"

    readonly property string pamConfigDirectory: "/etc/pam.d"
    backend: nativePam
    successResult: PamResult.Success
    failedResult: PamResult.Failed
    maxTriesResult: PamResult.MaxTries

    Component.onCompleted: {
        if (!probePamService)
            return;
        if (Quickshell.env("POND_PAM_SERVICE")) {
            pamReady = true;
        } else {
            detectPamServiceProc.running = true;
        }
    }

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

    PamContext {
        id: nativePam
        configDirectory: root.pamConfigDirectory
        config: root.pamConfig
        // An empty user makes PamContext resolve getuid() itself. Avoid trusting
        // a mutable environment variable for the authentication identity.
        user: ""
    }
}
