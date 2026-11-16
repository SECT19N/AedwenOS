// The M3 Expressive loading indicator (System Surfaces: "the loading shape
// morphs"), as Compose's indeterminate LoadingIndicator draws it:
//
//   soft burst -> 9-sided cookie -> pentagon -> pill -> sunny
//   -> 4-sided cookie -> oval -> (soft burst)
//
// It starts a new morph every 650 ms, driven by a spring (damping 0.6,
// stiffness 200). Each morph turns the shape a further 90 degrees, overshoot
// included, on top of a steady 360 degrees every 4666 ms. The shapes come
// from m3shapes.js, which scripts/generate-m3-shapes.py ports from androidx.
// The Plymouth loader frames (scripts/generate-plymouth-assets.py) use the
// same shapes and timing.
//
// With animations disabled it is a static circle with a pulsing opacity
// (design: reduced motion).
import QtQuick
import QtQuick.Shapes
import "m3shapes.js" as M3

Item {
    id: root
    property color color: Theme.primary
    property bool running: visible

    implicitWidth: 28
    implicitHeight: 28

    // milliseconds since the indicator started
    property real elapsed: 0

    readonly property var points: {
        const n = M3.loader.length
        const step = Math.floor(elapsed / M3.morphIntervalMs)
        const i = step % n
        const progress = M3.spring(elapsed - step * M3.morphIntervalMs)
        const from = M3.loader[i]
        const to = i === n - 1 ? M3.loaderClose : M3.loader[i + 1]
        // the shape takes the clamped progress; the rotation keeps the
        // overshoot, which is where the bounce shows (as in Compose)
        const shape = M3.lerp(from, to, Math.max(0, Math.min(1, progress)))
        const deg = progress * 90 + ((step + 1) % 4) * 90 + (elapsed % M3.globalRotationMs) / M3.globalRotationMs * 360
        return M3.place(shape, width, height, M3.loaderScale / M3.activeScale, deg)
    }

    Shape {
        anchors.fill: parent
        visible: Theme.animate
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            fillColor: root.color
            strokeWidth: -1
            PathPolyline { path: root.points }
        }
    }
    Rectangle {
        visible: !Theme.animate
        anchors.centerIn: parent
        width: Math.min(parent.width, parent.height) * 0.8
        height: width
        radius: width / 2
        color: root.color
        SequentialAnimation on opacity {
            running: root.running && !Theme.animate
            loops: Animation.Infinite
            NumberAnimation { to: 0.4; duration: 700 }
            NumberAnimation { to: 1; duration: 700 }
        }
    }
    FrameAnimation {
        running: root.running && Theme.animate
        onTriggered: root.elapsed = (root.elapsed + frameTime * 1000) % (4 * M3.morphIntervalMs * M3.loader.length * M3.globalRotationMs)
    }
}
