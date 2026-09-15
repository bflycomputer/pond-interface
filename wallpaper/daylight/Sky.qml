import QtQuick
import QtQuick.Window
import "SkyState.js" as SkyState

ShaderEffect {
    id: sky

    property var atmosphere: SkyState.DEFAULTS
    property bool live: true
    property date now: new Date()
    property real pixelRatio: Window.window?.devicePixelRatio ?? 1
    readonly property real hour: now.getHours() + now.getMinutes() / 60
        + now.getSeconds() / 3600 + now.getMilliseconds() / 3600000
    readonly property var skyState: SkyState.skyState(hour, atmosphere)

    function stop(index: int): vector4d {
        const band = skyState.stops[index];
        return Qt.vector4d(band.color[0], band.color[1], band.color[2], band.position);
    }

    property vector4d stop0: stop(0)
    property vector4d stop1: stop(1)
    property vector4d stop2: stop(2)
    property vector4d stop3: stop(3)
    property vector4d stop4: stop(4)
    property vector4d stop5: stop(5)
    property vector4d settings: Qt.vector4d(skyState.options.brightness, skyState.options.saturation, skyState.options.warmth, 0)
    property vector2d resolution: Qt.vector2d(width * pixelRatio, height * pixelRatio)
    fragmentShader: Qt.resolvedUrl("sky.frag.qsb")
    onStatusChanged: if (status === ShaderEffect.Error) console.error("Daylight shader:", log)

    Timer {
        interval: 1000
        repeat: true
        running: sky.live && sky.visible
        onRunningChanged: if (running) sky.now = new Date()
        onTriggered: sky.now = new Date()
    }
}
