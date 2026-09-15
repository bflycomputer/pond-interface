import QtQuick
import Quickshell.Io

Item {
    id: root
    property string userName: ""
    property string displayName: userName

    Process {
        command: ["/usr/bin/id", "-un"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                root.userName = text.trim();
                if (root.userName)
                    account.exec(["/usr/bin/getent", "passwd", root.userName]);
            }
        }
    }
    Process {
        id: account
        stdout: StdioCollector {
            onStreamFinished: {
                const name = (text.trim().split(":")[4] || "").split(",")[0];
                root.displayName = name || root.userName;
            }
        }
    }
}
