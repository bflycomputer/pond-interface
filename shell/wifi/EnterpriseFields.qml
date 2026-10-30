pragma ComponentBehavior: Bound
import QtQuick
import ".."

Column {
  id: root
  property string eap: "peap"
  property string innerAuth: "mschapv2"
  readonly property var eapOptions: [
    { label: "PEAP", mode: "peap" },
    { label: "TTLS", mode: "ttls" }
  ]
  readonly property var innerOptions: eap === "ttls" ? [
    { label: "PAP", mode: "pap" },
    { label: "MSCHAPv2", mode: "mschapv2" },
    { label: "MSCHAP", mode: "mschap" },
    { label: "CHAP", mode: "chap" }
  ] : [{ label: "MSCHAPv2", mode: "mschapv2" }]
  readonly property bool complete: username.text.trim() !== ""
      && password.text !== "" && domain.text.trim() !== ""
  readonly property string secret: password.text
  readonly property var settings: ({
    identity: username.text.trim(), eap: eap, phase2: innerAuth,
    anonymousIdentity: anonymous.text.trim(), domain: domain.text.trim(),
    caCertificate: certificate.text.trim()
  })
  signal menuRequested(var menu)
  signal accepted()
  signal fieldFocused(var field)

  width: PanelStyle.fieldWidth
  spacing: 20

  function select(setting, mode) {
    if (setting === "eap") {
      eap = mode;
      innerAuth = mode === "ttls" ? "pap" : "mschapv2";
    } else if (setting === "inner") {
      innerAuth = mode;
    }
  }
  function focusEditor() { username.focusEditor(); }

  component InputField: Field {
    onFocusedChanged: if (focused) root.fieldFocused(this)
  }

  component FormRow: Column {
    property string label
    width: PanelStyle.fieldWidth
    spacing: 5
    Text {
      text: parent.label
      color: "white"
      font.family: Theme.fontFamily
      font.weight: Font.Medium
      font.pixelSize: 13
      height: 16
    }
  }

  FormRow {
    label: qsTrId("pond.username")
    InputField { id: username; placeholderText: qsTrId("pond.enter_username") }
  }
  FormRow {
    label: qsTrId("pond.password")
    InputField {
      id: password
      password: true
      placeholderText: qsTrId("pond.enter_password")
      onAccepted: root.accepted()
    }
  }
  FormRow {
    label: qsTrId("pond.authentication")
    SelectField {
      text: root.eap.toUpperCase()
      onActiveFocusChanged: if (activeFocus) root.fieldFocused(this)
      onClicked: root.menuRequested({setting: "eap", options: root.eapOptions,
                                    mode: root.eap, anchor: this})
    }
  }
  FormRow {
    label: qsTrId("pond.inner_authentication")
    visible: root.innerOptions.length > 1
    SelectField {
      text: root.innerOptions.find(option => option.mode === root.innerAuth)?.label || ""
      onActiveFocusChanged: if (activeFocus) root.fieldFocused(this)
      onClicked: root.menuRequested({setting: "inner", options: root.innerOptions,
                                    mode: root.innerAuth, anchor: this})
    }
  }
  FormRow {
    label: qsTrId("pond.server_domain")
    InputField {
      id: domain
      placeholderText: qsTrId("pond.e_g_wifi_example_edu")
      onAccepted: root.accepted()
    }
  }
  FormRow {
    label: qsTrId("pond.anonymous_identity_optional")
    InputField { id: anonymous; placeholderText: qsTrId("pond.enter_anonymous_identity") }
  }
  FormRow {
    label: qsTrId("pond.ca_certificate_optional")
    InputField {
      id: certificate
      placeholderText: "/path/to/certificate.pem"
      onAccepted: root.accepted()
    }
  }
}
