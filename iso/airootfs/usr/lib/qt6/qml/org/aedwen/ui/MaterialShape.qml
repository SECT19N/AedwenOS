// One of the 35 Material 3 Expressive shapes (m3shapes.js, ported from
// androidx MaterialShapes), filled, scaled to the item's box:
//
//   MaterialShape { shape: "cookie9"; color: Theme.terC; width: 48; height: 48 }
//
// Changing `shape` morphs to the new one with the spring (or the standard
// curve in the baseline variant); children are drawn on top, centred by
// whatever anchors they use. Names: circle square slanted arch fan arrow
// semiCircle oval pill triangle diamond clamShell pentagon gem sunny
// verySunny cookie4 cookie6 cookie7 cookie9 cookie12 ghostish clover4
// clover8 burst softBurst boom softBoom flower puffy puffyDiamond
// pixelCircle pixelTriangle bun heart.
import QtQuick
import QtQuick.Shapes
import "m3shapes.js" as M3

Item {
    id: root
    property string shape: "circle"
    property color color: Theme.primary
    property real angle: 0             // degrees, about the centre

    // morph state: from -> to at progress t
    property var _from: M3.points[shape] || M3.points.circle
    property var _to: _from
    property real _t: 1
    property bool _morphing: false

    onShapeChanged: {
        const next = M3.points[shape]
        if (!next) {
            console.warn("MaterialShape: unknown shape", shape)
            return
        }
        if (!Theme.animate || width <= 0) {
            _from = next; _to = next; _t = 1; _morphing = false
            return
        }
        _from = M3.lerp(_from, _to, _t)
        _to = M3.align(_from, next)
        _t = 0
        _morphing = true
        anim.restart()
    }
    NumberAnimation {
        id: anim
        target: root
        property: "_t"
        from: 0
        to: 1
        duration: Theme.dur
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Theme.morphEasing
        onFinished: root._morphing = false
    }

    function _place(p) {
        const out = []
        const a = angle * Math.PI / 180, c = Math.cos(a), s = Math.sin(a)
        for (let i = 0; i < p.length; i += 2) {
            const x = (p[i] - 0.5) * width, y = (p[i + 1] - 0.5) * height
            out.push(Qt.point(width / 2 + x * c - y * s, height / 2 + x * s + y * c))
        }
        out.push(out[0])
        return out
    }

    implicitWidth: 40
    implicitHeight: 40

    // at rest: the exact outline (cubics); while morphing: the sampled one
    Shape {
        anchors.fill: parent
        visible: !root._morphing
        preferredRendererType: Shape.CurveRenderer
        transform: [
            Scale { xScale: root.width; yScale: root.height },
            Rotation { origin.x: root.width / 2; origin.y: root.height / 2; angle: root.angle }
        ]
        ShapePath {
            fillColor: root.color
            strokeWidth: -1
            PathSvg { path: M3.path[root.shape] || M3.path.circle }
        }
    }
    Shape {
        anchors.fill: parent
        visible: root._morphing
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            fillColor: root.color
            strokeWidth: -1
            PathPolyline { path: root._morphing ? root._place(M3.lerp(root._from, root._to, Math.max(0, Math.min(1, root._t)))) : [] }
        }
    }
}
