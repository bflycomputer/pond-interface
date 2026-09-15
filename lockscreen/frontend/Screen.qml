import QtQuick
import "form" as Form

Item {
    id: root

    required property var controller
    property bool showPresentation: true
    property int maximumLength: 32767
    property alias displayName: view.displayName
    property alias wifiConnected: view.wifiConnected
    property alias multipleUsers: view.multipleUsers
    property alias compositors: view.compositors
    property alias compositorIndex: view.compositorIndex

    signal userStepRequested(int direction)
    signal compositorRequested(int index)

    Form.PasswordInput {
        id: input
        inputContext: root.controller
        controller: root.controller.controller
        inputBlocked: !root.controller.acceptingInput
        maximumLength: root.maximumLength
        onSubmitRequested: root.controller.submit()
        onCancelRequested: root.controller.powerActions.cancel()
    }
    Layout {
        id: view
        anchors.fill: parent
        visible: root.showPresentation
        controller: root.controller.controller
        exitTransition: root.controller.exitTransition
        inputTarget: input
        revealText: showPassword || revealContentVisible ? input.text : ""
        interactive: root.controller.acceptingInput
        powerInteractive: root.controller.active
        restartInteractive: root.controller.active
        powerCountdownActive: root.controller.powerActions.active
        powerCountdownRemainingMs: root.controller.powerActions.remaining
        powerAction: root.controller.powerActions.action
        onSubmitRequested: root.controller.submit()
        onShutdownRequested: root.controller.requestPower("shutdown")
        onRestartRequested: root.controller.requestPower("restart")
        onUserStepRequested: direction => root.userStepRequested(direction)
        onCompositorRequested: index => root.compositorRequested(index)
    }
    MouseArea {
        anchors.fill: parent
        enabled: !root.showPresentation
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        onEntered: input.forceActiveFocus()
    }
    Connections {
        target: root.controller
        function onInputReset() { view.showPassword = false; }
        function onRefocusRequested() {
            if (input.enabled)
                input.forceActiveFocus();
        }
    }
}
