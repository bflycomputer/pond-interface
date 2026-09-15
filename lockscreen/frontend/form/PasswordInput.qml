import QtQuick

TextInput {
    id: root

    required property var inputContext
    required property var controller
    property bool inputBlocked: false

    signal submitRequested

    // Keep the native editor in the focus tree while making it visually
    // absent. `visible: false` can revoke active focus in Qt Quick.
    width: 1
    height: 1
    opacity: 0
    cursorVisible: false
    activeFocusOnTab: false
    enabled: controller.acceptingInput && !inputContext.authenticationPending && !inputBlocked
    echoMode: TextInput.Password
    passwordMaskDelay: 0
    inputMethodHints: Qt.ImhSensitiveData | Qt.ImhNoPredictiveText

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            submitRequested();
            event.accepted = true;
        }
    }

    onTextEdited: {
        if (inputContext.currentText !== text)
            inputContext.currentText = text;
        controller.syncLength(text.length);
    }

    onEnabledChanged: {
        if (enabled)
            Qt.callLater(forceActiveFocus);
    }

    Connections {
        target: root.inputContext

        function onCurrentTextChanged() {
            if (root.text !== root.inputContext.currentText)
                root.text = root.inputContext.currentText;
            if (!root.inputContext.authenticationPending && !root.inputBlocked)
                root.controller.syncLength(root.inputContext.currentText.length);
        }
    }

    Connections {
        target: root.controller

        function onErrorAnimationFinished() {
            if (root.enabled)
                root.forceActiveFocus();
        }
    }

    Component.onCompleted: {
        // A lock surface can be recreated after a monitor topology change.
        // Seed it from the shared editor before it is allowed to take focus.
        if (text !== inputContext.currentText)
            text = inputContext.currentText;
        if (!inputContext.authenticationPending && !inputBlocked)
            controller.syncLength(inputContext.currentText.length);
        Qt.callLater(forceActiveFocus);
    }
}
