import QtQuick
import Quickshell
import Quickshell.Wayland
import "." as Polkit
import ".." as Shell

PanelWindow {
  id: root

  // Quickshell.Services.Polkit AuthFlow for the active request.
  required property var flow

  readonly property var identities: flow ? flow.identities : []
  readonly property var identity: flow ? flow.selectedIdentity : null
  readonly property string identityName: identity ? String(identity.displayName ?? "") : ""
  readonly property bool awaitingInput: !!flow && flow.isResponseRequired
  // Between sending a password and PAM asking again or finishing.
  property bool submitted: false
  // Enter was pressed before PAM asked for the password. The polkit helper is
  // socket activated and can take a moment to start, so keep the field usable
  // and send the password once the prompt arrives instead of dropping input.
  property bool pendingSubmit: false
  // Stays true after success until the dialog closes, so the button doesn't
  // flip back to "Authenticate" for a frame.
  readonly property bool checking: (submitted && !awaitingInput) || pendingSubmit
  readonly property bool canSubmit: !submitted && password.text.length > 0

  readonly property string promptLabel: {
    const prompt = String(flow?.inputPrompt ?? "").trim();
    if (prompt === "" || /^password:?$/i.test(prompt))
      return identityName ? "Password for " + identityName : "Password";
    return prompt.replace(/:$/, "");
  }
  // A wrong password replaces the label above the field instead of adding a
  // line, so the card shakes without also resizing. Cleared once the user
  // starts typing again.
  property bool showFailure: false
  // PAM's own messages (e.g. pam_faillock's lockout notice) can be long, so
  // they get a line under the field.
  readonly property string statusText: flow?.supplementaryMessage ?? ""
  readonly property bool statusIsError: !!flow && flow.supplementaryIsError

  function submit() {
    if (!canSubmit) return;
    if (!awaitingInput) {
      pendingSubmit = true;
      return;
    }
    pendingSubmit = false;
    submitted = true;
    flow.submit(password.text);
    password.text = "";
  }
  function cancel() {
    if (flow) flow.cancelAuthenticationRequest();
  }
  function cycleIdentity() {
    if (!flow || identities.length < 2) return;
    const index = identities.indexOf(identity);
    flow.selectedIdentity = identities[(index + 1) % identities.length];
  }

  color: "transparent"
  anchors { left: true; right: true; top: true; bottom: true }
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.namespace: "pond-polkit-" + (screen ? screen.name : "unknown")
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
  WlrLayershell.exclusionMode: ExclusionMode.Ignore
  // Blur like the shell's other panels (see the pond layer-rule in
  // config/niri/shell/config.kdl), and like them only once the card is mostly
  // visible so the blur doesn't show before the card does.
  BackgroundEffect.blurRegion: Shell.Theme.translucent ? cardBlur : null
  Region {
    id: cardBlur
    item: frame.opacity > Shell.PanelStyle.blurRevealOpacity ? card : null
    radius: card.radius
  }
  // True once the open animation has finished.
  readonly property bool revealed: backdrop.opacity >= backdrop.target

  property bool shown: false
  Component.onCompleted: {
    shown = true;
    Qt.callLater(password.focusEditor);
  }
  onAwaitingInputChanged: {
    if (!awaitingInput) return;
    submitted = false;
    Qt.callLater(password.focusEditor);
    if (pendingSubmit) Qt.callLater(submit);
  }

  Connections {
    target: root.flow
    function onAuthenticationFailed() {
      root.showFailure = true;
      shake.restart();
    }
  }

  Rectangle {
    id: backdrop
    readonly property real target: Shell.Theme.colors.overlayOpacity
    anchors.fill: parent
    color: "#101010"
    opacity: root.shown ? target : 0
    Behavior on opacity {
      NumberAnimation { duration: Shell.PanelStyle.openDuration; easing.type: Easing.OutCubic }
    }
  }
  // Clicking outside refocuses the field. Cancelling needs an explicit action,
  // since every cancelled prompt counts as a failed login with pam_faillock.
  MouseArea {
    anchors.fill: parent
    acceptedButtons: Qt.AllButtons
    onClicked: password.focusEditor()
  }

  FocusScope {
    anchors.fill: parent
    focus: true
    Keys.onEscapePressed: root.cancel()

    Item {
      id: frame
      anchors.centerIn: parent
      width: Shell.PanelStyle.width
      height: content.implicitHeight + 40
      opacity: root.shown ? 1 : 0
      scale: root.shown ? 1 : 0.96
      onScaleChanged: cardBlur.changed()
      onXChanged: cardBlur.changed()
      onHeightChanged: cardBlur.changed()
      Behavior on opacity {
        NumberAnimation { duration: Shell.PanelStyle.openDuration; easing.type: Easing.OutCubic }
      }
      Behavior on scale {
        NumberAnimation { duration: Shell.PanelStyle.openDuration; easing.type: Easing.OutCubic }
      }
      // Only animate size changes after opening (e.g. an error line appearing).
      // While opening, the text is still being laid out and the card would
      // visibly grow into place.
      Behavior on height {
        enabled: root.revealed
        NumberAnimation { duration: Shell.PanelStyle.controlDuration; easing.type: Easing.OutCubic }
      }

      SequentialAnimation {
        id: shake
        NumberAnimation { target: frame.anchors; property: "horizontalCenterOffset"; to: -10; duration: 50 }
        NumberAnimation { target: frame.anchors; property: "horizontalCenterOffset"; to: 8; duration: 70 }
        NumberAnimation { target: frame.anchors; property: "horizontalCenterOffset"; to: -5; duration: 60 }
        NumberAnimation { target: frame.anchors; property: "horizontalCenterOffset"; to: 0; duration: 60 }
      }

      Shell.Shadow {
        anchors.fill: card
        cornerRadius: card.radius
        shadows: Shell.PanelStyle.frontShadows
      }

      // Drawn like settings/Modal.qml: the shell's modal colours, not the
      // panel ones, since this is a full-screen modal over the dimmed overlay.
      Rectangle {
        id: card
        readonly property Gradient fill: Shell.PanelStyle.modalGradient
        anchors.fill: parent
        radius: Shell.PanelStyle.radius
        color: fill ? "transparent" : Shell.Theme.colors.modalSurface
        antialiasing: true

        Shell.GradientFill { fill: card.fill }
        Shell.PanelBorder {
          radius: card.radius
          color: Shell.PanelStyle.modalBorder
          visible: Shell.Theme.translucent
          z: 4
        }

        // Stop card clicks from reaching the backdrop.
        MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons }

        Column {
          id: content
          x: 20
          y: 20
          width: parent.width - 40

          Text {
            width: parent.width
            text: "Authentication required"
            color: Shell.Theme.colors.text
            font.family: Shell.Theme.titleFontFamily
            font.pixelSize: 20
            wrapMode: Text.WordWrap
          }

          Item { width: 1; height: 10 }

          Text {
            width: parent.width
            text: root.flow?.message ?? ""
            visible: text.length > 0
            color: Shell.Theme.colors.text
            opacity: 0.7
            font.family: Shell.Theme.fontFamily
            font.weight: Font.Medium
            font.pixelSize: 13
            lineHeight: 1.15
            wrapMode: Text.Wrap
          }

          Item { width: 1; height: 22 }

          Item {
            width: parent.width
            height: label.implicitHeight
            Text {
              id: label
              width: parent.width - (switcher.visible ? switcher.width + 8 : 0)
              text: root.showFailure ? "Incorrect password, try again" : root.promptLabel
              elide: Text.ElideRight
              color: root.showFailure ? Shell.Theme.colors.errorText : Shell.Theme.colors.text
              font.family: Shell.Theme.fontFamily
              font.weight: Font.Medium
              font.pixelSize: 15
            }
            Text {
              id: switcher
              anchors.right: parent.right
              anchors.baseline: label.baseline
              visible: root.identities.length > 1
              text: "Switch user"
              color: switchHover.hovered ? Shell.PanelStyle.accent : Shell.Theme.colors.text
              opacity: switchHover.hovered ? 1 : 0.5
              font.family: Shell.Theme.fontFamily
              font.weight: Font.Medium
              font.pixelSize: 12
              HoverHandler { id: switchHover; cursorShape: Qt.PointingHandCursor }
              TapHandler { onTapped: root.cycleIdentity() }
            }
          }

          Item { width: 1; height: 8 }

          Shell.Field {
            id: password
            width: parent.width
            password: !(root.flow?.responseVisible ?? false)
            readOnly: root.submitted || root.pendingSubmit
            opacity: readOnly ? 0.5 : 1
            placeholderText: "Enter password"
            onAccepted: root.submit()
            onTextChanged: if (text.length > 0) root.showFailure = false
            Behavior on opacity { NumberAnimation { duration: Shell.PanelStyle.controlDuration } }
          }

          Item {
            width: parent.width
            height: status.text.length > 0 ? status.implicitHeight + 10 : 0
            clip: true
            Behavior on height { NumberAnimation { duration: Shell.PanelStyle.controlDuration } }
            Text {
              id: status
              y: 10
              width: parent.width
              text: root.statusText
              wrapMode: Text.Wrap
              color: root.statusIsError ? Shell.Theme.colors.errorText : Shell.Theme.colors.text
              opacity: root.statusIsError ? 1 : 0.6
              font.family: Shell.Theme.fontFamily
              font.weight: Font.Medium
              font.pixelSize: 12
            }
          }

          Item { width: 1; height: 20 }

          Row {
            width: parent.width
            spacing: 8
            Polkit.Button {
              width: (parent.width - parent.spacing) / 2
              text: "Cancel"
              onClicked: root.cancel()
            }
            Polkit.Button {
              width: (parent.width - parent.spacing) / 2
              // Progress shows in the button so the card doesn't resize on every
              // submit; the status line below the field is for errors only.
              text: root.checking ? "Checking…" : "Authenticate"
              busy: root.checking
              primary: true
              interactive: root.canSubmit
              onClicked: root.submit()
            }
          }

          Item { width: 1; height: 14 }

          Text {
            width: parent.width
            text: root.flow?.actionId ?? ""
            visible: text.length > 0
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideMiddle
            color: Shell.Theme.colors.text
            opacity: 0.3
            font.family: Shell.Theme.plexFontFamily
            font.pixelSize: 10
          }
        }
      }
    }
  }
}
