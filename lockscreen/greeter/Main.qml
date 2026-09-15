pragma ComponentBehavior: Bound
import QtQuick
import QtQml.Models
import Pond.System
import "../frontend" as Frontend

Item {
    id: root
    property var loginBackend: sddm
    property var accountModel: userModel
    property var desktopModel: sessionModel
    property int userIndex: Math.max(0, accountModel.lastIndex)
    property int sessionIndex: Math.max(0, desktopModel.lastIndex)
    property int usersRevision: 0
    property int sessionsRevision: 0
    property bool requestPending: false
    readonly property var selectedUser: {
        usersRevision;
        return users.objectAt(userIndex);
    }
    readonly property var sessionNames: {
        sessionsRevision;
        return Array.from({length: desktops.count}, (_, index) => (desktops.objectAt(index) as Desktop)?.name || "");
    }

    function selectUser(direction) {
        if (!ui.acceptingInput || users.count < 2)
            return;
        userIndex = (userIndex + direction + users.count) % users.count;
        ui.resetInput();
    }
    function selectSession(index) {
        if (!ui.acceptingInput || index < 0 || index >= desktops.count)
            return;
        sessionIndex = index;
        ui.refocusRequested();
    }

    component Account: QtObject {
        required property string name
        required property string realName
    }
    component Desktop: QtObject { required property string name }

    Instantiator {
        id: users
        model: root.accountModel
        delegate: Account {}
        onObjectAdded: root.usersRevision++
        onObjectRemoved: root.usersRevision++
    }
    Instantiator {
        id: desktops
        model: root.desktopModel
        delegate: Desktop {}
        onObjectAdded: root.sessionsRevision++
        onObjectRemoved: root.sessionsRevision++
    }
    NetworkStatus { id: network }
    QtObject {
        id: power
        function shutdown() {
            if (root.loginBackend.canPowerOff) root.loginBackend.powerOff();
        }
        function reboot() {
            if (root.loginBackend.canReboot) root.loginBackend.reboot();
        }
    }
    Frontend.Controller {
        id: ui
        powerBackend: power
        inputBlocked: !root.selectedUser || root.sessionIndex >= desktops.count
        onSubmitRequested: credential => {
            root.requestPending = true;
            root.loginBackend.login(root.selectedUser.name, credential, root.sessionIndex);
        }
        onSuccessAnimationFinished: {
            exitTransition.animationPaused = false;
            exitTransition.start();
        }
        onFinished: active = false
    }
    Frontend.Screen {
        anchors.fill: parent
        controller: ui
        displayName: root.selectedUser ? root.selectedUser.realName || root.selectedUser.name : ""
        multipleUsers: users.count > 1
        wifiConnected: network.wifiConnected
        compositors: root.sessionNames
        compositorIndex: root.sessionIndex
        onUserStepRequested: direction => root.selectUser(direction)
        onCompositorRequested: index => root.selectSession(index)
    }
    Connections {
        target: root.loginBackend
        function onLoginSucceeded() {
            if (!root.requestPending) return;
            root.requestPending = false;
            ui.authenticationSucceeded();
        }
        function onLoginFailed() {
            if (!root.requestPending) return;
            root.requestPending = false;
            ui.authenticationFailed();
        }
        function onSocketDisconnected() {
            root.requestPending = false;
            ui.active = false;
            ui.resetInput();
        }
    }
}
