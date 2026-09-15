import QtQuick
import "form"

Item {
    id: root

    required property var controller
    required property var exitTransition
    property var inputTarget: null
    property string revealText: ""
    property bool showPassword: false
    readonly property bool revealContentVisible: lockDisplay.revealContentVisible
    property alias displayPhase: lockDisplay.displayPhase
    property bool interactive: true
    property bool powerInteractive: interactive
    property bool restartInteractive: false
    property bool wifiConnected: false
    property string displayName: ""
    property bool multipleUsers: false
    property var compositors: []
    property string selectedCompositor: ""
    property bool powerCountdownActive: false
    property int powerCountdownRemainingMs: 0
    property string powerAction: "shutdown"
    property string statusMessage: ""
    property date now: new Date()
    property Component backgroundComponent: null

    signal submitRequested
    signal shutdownRequested
    signal restartRequested
    signal userStepRequested(int direction)
    signal compositorRequested(string name)

    clip: true

    readonly property real canvasHeight: 1080
    // Uniform scaling keeps the lock centered while wide layouts retain true
    // physical screen edges for the reveal/power controls and footer copy.
    readonly property real layoutScale: Math.min(height / canvasHeight, width / 960)

    onInteractiveChanged: {
        if (!interactive)
            showPassword = false;
    }

    function refocusInput() {
        if (inputTarget)
            inputTarget.forceActiveFocus();
    }

    Theme {
        id: theme
    }

    Item {
        id: canvas
        objectName: "lockCanvas"
        width: root.width / root.layoutScale
        height: root.canvasHeight
        x: 0
        y: (root.height - height * root.layoutScale) / 2
        transform: Scale {
            origin.x: 0
            origin.y: 0
            xScale: root.layoutScale
            yScale: root.layoutScale
        }

        MouseArea {
            anchors.fill: parent
            enabled: root.interactive
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton
            onEntered: root.refocusInput()
            onClicked: root.refocusInput()
        }

        Item {
            id: backdrop
            anchors.fill: parent
            Image {
                anchors.fill: parent
                source: Qt.resolvedUrl("assets/lock-background.png")
                fillMode: Image.PreserveAspectCrop
            }
            Loader {
                objectName: "background"
                anchors.fill: parent
                active: root.backgroundComponent !== null
                sourceComponent: root.backgroundComponent
            }
            Image {
                id: moon
                objectName: "moon"
                x: (parent.width - width) / 2
                y: 704
                width: 1226
                height: 1532
                source: Qt.resolvedUrl("assets/moon.png")
                fillMode: Image.PreserveAspectFit
                asynchronous: false
                opacity: root.exitTransition.moonVisible ? 1 : 0

                Behavior on opacity { NumberAnimation { duration: 65 } }
            }
        }
        ShaderEffectSource {
            id: backdropTexture
            anchors.fill: parent
            sourceItem: backdrop
            hideSource: true
            // Keep the texture available to the footer blend during handoff.
            opacity: root.exitTransition.revealedQuadrantCount === 0 ? 1 : 0
        }
        Image {
            x: (canvas.width - 1226) / 2; y: 704
            width: 1226; height: 1532
            source: Qt.resolvedUrl("assets/moon.png")
            visible: root.exitTransition.revealedQuadrantCount > 0 && root.exitTransition.moonVisible
        }

        Item {
            id: periphery
            objectName: "periphery"
            anchors.fill: parent
            opacity: root.exitTransition.peripheryVisible ? 1 : 0
            visible: opacity > 0

            Behavior on opacity { NumberAnimation { duration: 60 } }

            UserHeader {
                objectName: "identityHeader"
                width: parent.width
                theme: theme
                displayName: root.displayName
                multipleUsers: root.multipleUsers
                compositors: root.compositors
                selectedCompositor: root.selectedCompositor
                enabled: root.interactive
                onUserStepRequested: direction => root.userStepRequested(direction)
                onCompositorRequested: name => root.compositorRequested(name)
            }

            Text {
                objectName: "lockDate"
                opacity: lockDisplay.dateTimeVisible ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 150 } }
                x: (80 + (canvas.width - 400) / 2) / 2 - 19 - width / 2
                y: 506
                text: Qt.formatDate(root.now, "ddd, MMM d")
                color: theme.text
                font.family: theme.displayFont
                font.styleName: "Book"
                font.pixelSize: 20
            }

            Text {
                objectName: "lockTime"
                opacity: lockDisplay.dateTimeVisible ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 150 } }
                x: ((canvas.width + 400) / 2 + canvas.width - 80) / 2 - 24 - width / 2
                y: 506
                text: Qt.formatTime(root.now, "h:mm AP")
                color: theme.text
                font.family: theme.displayFont
                font.styleName: "Book"
                font.pixelSize: 20
            }

            Image {
                objectName: "wifiStatus"
                x: canvas.width - 34
                y: 10
                width: 24
                height: 24
                source: Qt.resolvedUrl("assets/wifi.svg")
                asynchronous: false
                visible: root.wifiConnected
            }

            Item {
                objectName: "revealButton"
                x: 0
                y: 480
                width: 80
                height: 80

                Image {
                    anchors.fill: parent
                    source: Qt.resolvedUrl(revealMouse.containsMouse ? "assets/reveal-hover.svg"
                        : root.showPassword ? "assets/reveal-open.svg" : "assets/reveal.svg")
                    asynchronous: false
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: root.interactive
                    id: revealMouse
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.refocusInput();
                        root.showPassword = !root.showPassword;
                    }
                }
            }

            PowerMenu {
                objectName: "powerMenu"
                x: canvas.width - 80
                y: 480
                theme: theme
                enabled: root.powerInteractive
                restartEnabled: root.restartInteractive
                onShutdownRequested: {
                    if (root.interactive)
                        root.refocusInput();
                    root.shutdownRequested();
                }
                onRestartRequested: {
                    if (root.interactive)
                        root.refocusInput();
                    root.restartRequested();
                }
            }

            SoftLightText {
                backgroundTexture: backdropTexture
                backgroundSize: Qt.size(canvas.width, canvas.height)
                x: 10
                y: 1026
                text: "Pre-release version"
                font.family: theme.displayFont
                font.styleName: "Regular"
                font.pixelSize: 39
                font.letterSpacing: -1.17
            }

            SoftLightText {
                backgroundTexture: backdropTexture
                backgroundSize: Qt.size(canvas.width, canvas.height)
                x: canvas.width - 240
                y: 1041
                width: 228
                text: "Some features may not work as expected. Please report any issues or bugs."
                font.family: theme.uiFont
                font.styleName: "Medium"
                font.pixelSize: 11
                font.letterSpacing: 0.11
                wrapMode: Text.WordWrap
            }
        }

        Form {
            id: lockDisplay
            objectName: "lockDisplay"
            displayScale: root.layoutScale
            anchors.fill: parent
            controller: root.controller
            exitStep: root.exitTransition.exitStep
            theme: theme
            revealText: root.revealText
            showPassword: root.showPassword
            interactive: root.interactive
            onSubmitRequested: root.submitRequested()
        }

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            y: 970
            width: noticeText.implicitWidth + 36
            height: 40
            color: "#e6643957"
            border.width: 1
            border.color: theme.lavender
            visible: noticeText.text.length > 0

            Text {
                id: noticeText
                anchors.centerIn: parent
                text: {
                    if (root.powerCountdownActive)
                        return (root.powerAction === "restart" ? "Restart in " : "Power off in ")
                            + Math.max(1, Math.ceil(root.powerCountdownRemainingMs / 1000)) + "s — click again to confirm";
                    return root.statusMessage;
                }
                color: theme.lavender
                font.family: theme.uiFont
                font.pixelSize: 13
            }
        }
    }

    Timer {
        interval: 1000
        repeat: true
        running: true
        onTriggered: root.now = new Date()
    }
}
