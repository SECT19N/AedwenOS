// The M3E loading indicator: a filled shape that keeps rotating while it
// morphs circle -> burst -> cookie -> pentagon -> pill -> sunny -> 4-cookie
// with a springy overshoot, at constant area (same shapes as the Plymouth
// loader, scripts/generate-plymouth-assets.py). With animations disabled it
// is a static circle with a pulsing opacity (design: reduced motion).
import QtQuick
import QtQuick.Shapes

Item {
    id: root
    property color color: Theme.primary
    property bool running: visible

    implicitWidth: 28
    implicitHeight: 28

    readonly property int samples: 72
    // step + fraction through the morph, animated 0..7
    property real phase: 0

    function shapeR(i, t) {
        switch (i) {
        case 0: return 1
        case 1: return 1 + 0.10 * Math.cos(8 * t)
        case 2: return 1 + 0.07 * Math.cos(9 * t)
        case 3: {
            const n = 5, seg = 2 * Math.PI / n
            let acc = 0
            for (let k = -3; k <= 3; k++) {
                const tt = t + k * 0.04
                const local = (((tt - Math.PI / 2) % seg) + seg) % seg - seg / 2
                acc += Math.cos(Math.PI / n) / Math.cos(local)
            }
            return acc / 7
        }
        case 4: {
            const c = Math.abs(Math.cos(t)), s = Math.abs(Math.sin(t))
            return Math.pow(Math.pow(c / 1.0, 3.2) + Math.pow(s / 0.62, 3.2), -1 / 3.2)
        }
        case 5: return 1 + 0.12 * (Math.pow(Math.abs(Math.cos(4 * t)), 3) * 2 - 1)
        default: return 1 + 0.11 * Math.cos(4 * t)
        }
    }
    function spring(x) {
        // cubic-bezier(.34,1.45,.55,1) solved by bisection
        let lo = 0, hi = 1
        const bez = (t, p1, p2) => 3 * (1 - t) * (1 - t) * t * p1 + 3 * (1 - t) * t * t * p2 + t * t * t
        for (let n = 0; n < 20; n++) { const m = (lo + hi) / 2; if (bez(m, 0.34, 0.55) < x) lo = m; else hi = m }
        return bez((lo + hi) / 2, 1.45, 1)
    }
    readonly property var points: {
        const step = Math.floor(phase) % 7, p = phase - Math.floor(phase)
        const m = p < 0.3 ? 0 : (p - 0.3) / 0.7, k = spring(m)
        const rad = []
        let area = 0
        for (let i = 0; i < samples; i++) {
            const t = 2 * Math.PI * i / samples
            const a = shapeR(step, t), b = shapeR((step + 1) % 7, t)
            const r = Math.max(0.2, a + (b - a) * k)
            rad.push(r)
            area += r * r
        }
        const norm = Math.sqrt(Math.PI / (0.5 * area * 2 * Math.PI / samples))
        const rot = (140 * (step + 0.4 * p + 0.6 * k)) * Math.PI / 180
        const unit = Math.min(width, height) / 2 / 1.25
        const pts = []
        for (let i = 0; i <= samples; i++) {
            const t = 2 * Math.PI * (i % samples) / samples + rot
            const r = rad[i % samples] * norm * unit
            pts.push(Qt.point(width / 2 + r * Math.cos(t), height / 2 + r * Math.sin(t)))
        }
        return pts
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
    NumberAnimation on phase {
        running: root.running && Theme.animate
        from: 0
        to: 7
        duration: 7 * 560
        loops: Animation.Infinite
    }
}
