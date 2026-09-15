import QtQuick

Item {
    id: root
    required property var backgroundTexture
    required property size backgroundSize
    property alias text: ink.text
    property alias font: ink.font
    property alias wrapMode: ink.wrapMode
    implicitWidth: ink.implicitWidth
    implicitHeight: ink.implicitHeight

    Text {
        id: ink
        width: root.width
        color: "white"
    }
    ShaderEffectSource {
        id: inkSource
        sourceItem: ink
        hideSource: true
        visible: false
        live: true
    }
    ShaderEffect {
        anchors.fill: parent
        property var inkTexture: inkSource
        property var backgroundTexture: root.backgroundTexture
        property vector4d backgroundRect: Qt.vector4d(root.x / root.backgroundSize.width,
            root.y / root.backgroundSize.height, root.width / root.backgroundSize.width,
            root.height / root.backgroundSize.height)
        fragmentShader: Qt.resolvedUrl("shaders/soft-light.frag.qsb")
    }
}
