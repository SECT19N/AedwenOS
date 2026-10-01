// M3E slider: thick rounded active track, a gap, the inactive track, and a
// tall narrow handle. `value` is 0..to; `moved(value)` fires while dragging.
import QtQuick

Item {
    id: root
    property real from: 0
    property real to: 100
    property real value: 0
    property real stepSize: 1
    signal moved(real value)

    readonly property real pos: to > from ? Math.max(0, Math.min(1, (value - from) / (to - from))) : 0
    readonly property real handleX: pos * (width - handle.width)

    implicitWidth: 200
    implicitHeight: 32
    opacity: enabled ? 1 : 0.45

    Rectangle {          // active
        anchors.verticalCenter: parent.verticalCenter
        x: 0
        width: Math.max(0, root.handleX - 4)
        height: 16
        radius: 8
        color: Theme.primary
    }
    Rectangle {          // inactive
        anchors.verticalCenter: parent.verticalCenter
        x: root.handleX + handle.width + 4
        width: Math.max(0, root.width - x)
        height: 16
        radius: 8
        color: Theme.secC
    }
    Rectangle {
        id: handle
        x: root.handleX
        anchors.verticalCenter: parent.verticalCenter
        width: mouse.pressed ? 2 : 4
        height: root.height
        radius: 2
        color: Theme.primary
        Behavior on width { NumberAnimation { duration: Theme.durShort } }
    }
    MouseArea {
        id: mouse
        anchors.fill: parent
        enabled: root.enabled
        cursorShape: Qt.PointingHandCursor
        preventStealing: true
        function update(x) {
            const t = Math.max(0, Math.min(1, x / root.width))
            let v = root.from + t * (root.to - root.from)
            if (root.stepSize > 0) v = Math.round(v / root.stepSize) * root.stepSize
            if (v !== root.value) { root.value = v; root.moved(v) }
        }
        onPressed: mouse => update(mouse.x)
        onPositionChanged: mouse => { if (pressed) update(mouse.x) }
        onWheel: wheel => {
            const step = (root.to - root.from) / 20
            update(((root.value + (wheel.angleDelta.y > 0 ? step : -step) - root.from) / (root.to - root.from)) * root.width)
        }
    }
}
