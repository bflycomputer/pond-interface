pragma ComponentBehavior: Bound
import QtQuick
import "RevealLayout.js" as Layout

// Merge shared edges at their animated positions to keep each stroke one physical pixel wide.
Item {
    id: root
    property var boxes: []
    property real pixelScale: 1
    property real originX: 0
    property real originY: 0
    readonly property var segments: Layout.strokeSegments(boxes, pixelScale, originX, originY)
    // A stable pool avoids recreating delegates as edges move.
    // At most 22 boxes contribute 176 endpoints, bounding the segment count below 256.
    Repeater {
        model: 256
        delegate: Rectangle {
            required property int index
            readonly property var segment: root.segments[index] || {x:0, y:0, w:0, h:0, alpha:0}
            x: segment.x; y: segment.y
            width: segment.w; height: segment.h
            opacity: segment.alpha
            visible: opacity > 0
            color: "white"
            antialiasing: false
        }
    }
}
