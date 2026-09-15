pragma ComponentBehavior: Bound
import QtQuick

Item {
    id: root

    required property var exitTransition
    property url wallpaperSource: Qt.resolvedUrl("assets/lock-background.png")
    property color coverColor: "#1a1409"

    readonly property int splitX: Math.round(width * 1000 / 1920)
    readonly property int splitY: Math.round(height * 400 / 1080)

    readonly property var quadrants: [
        Qt.rect(0, 0, splitX, splitY),
        Qt.rect(0, splitY, splitX, height - splitY),
        Qt.rect(splitX, splitY, width - splitX, height - splitY),
        Qt.rect(splitX, 0, width - splitX, splitY)
    ]

    Repeater {
        model: 4
        delegate: Rectangle {
            required property int index
            readonly property rect bounds: root.quadrants[index]
            x: bounds.x
            y: bounds.y
            width: bounds.width
            height: bounds.height
            color: root.coverColor
            clip: true
            visible: root.exitTransition.revealedQuadrantCount < index + 1
            Image {
                x: -parent.x; y: -parent.y
                width: root.width; height: root.height
                source: root.wallpaperSource
                fillMode: Image.PreserveAspectCrop
            }
        }
    }
}
