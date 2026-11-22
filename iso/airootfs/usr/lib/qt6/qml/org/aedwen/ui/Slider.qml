// M3E slider (Desktop design: QUICK SETTINGS sliders). The active track
// (primary, round on the left, 4 px corners at the handle), a 4 px gap, a
// 4 x 44 px handle, another gap, then the inactive track (secondary
// container, mirrored) with a 4 px primary stop dot near its end. Tracks are
// Theme.sliderH tall: 40 px in Expressive, 16 px in baseline.
// `value` is from..to; `moved(value)` fires while dragging.
import QtQuick

Item {
    id: root
    activeFocusOnTab: true
    Keys.onLeftPressed: step(-1)
    Keys.onDownPressed: step(-1)
    Keys.onRightPressed: step(1)
    Keys.onUpPressed: step(1)
    function step(dir) {
        const v = Math.max(from, Math.min(to, value + dir * (stepSize > 0 ? stepSize : (to - from) / 20)))
        if (v !== value) { value = v; moved(v) }
    }
    property real from: 0
    property real to: 100
    property real value: 0
    property real stepSize: 1
    property int trackHeight: Theme.sliderH
    signal moved(real value)

    readonly property real pos: to > from ? Math.max(0, Math.min(1, (value - from) / (to - from))) : 0
    readonly property real handleX: pos * (width - handle.width)
    readonly property real th: Math.min(trackHeight, height)

    implicitWidth: 200
    implicitHeight: 44
    opacity: enabled ? 1 : 0.45

    Rectangle {          // active
        anchors.verticalCenter: parent.verticalCenter
        x: 0
        width: Math.max(0, root.handleX - 4)
        visible: width > 0
        height: root.th
        topLeftRadius: root.th / 2
        bottomLeftRadius: root.th / 2
        topRightRadius: Math.min(4, width / 2)
        bottomRightRadius: Math.min(4, width / 2)
        color: Theme.primary
        Behavior on height { NumberAnimation { duration: Theme.dur; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.morphEasing } }
    }
    Rectangle {          // inactive
        id: inactive
        anchors.verticalCenter: parent.verticalCenter
        x: root.handleX + handle.width + 4
        width: Math.max(0, root.width - x)
        visible: width > 0
        height: root.th
        topLeftRadius: Math.min(4, width / 2)
        bottomLeftRadius: Math.min(4, width / 2)
        topRightRadius: root.th / 2
        bottomRightRadius: root.th / 2
        color: Theme.secC
        Behavior on height { NumberAnimation { duration: Theme.dur; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.morphEasing } }
        Rectangle {      // stop indicator
            visible: inactive.width > 16
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            anchors.rightMargin: 6
            width: 4
            height: 4
            radius: 2
            color: Theme.primary
        }
    }
    Rectangle {
        id: handle
        x: root.handleX + (4 - width) / 2
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
        onPressed: mouse => { root.focus = false; update(mouse.x) }
        onPositionChanged: mouse => { if (pressed) update(mouse.x) }
        onWheel: wheel => {
            const step = (root.to - root.from) / 20
            update(((root.value + (wheel.angleDelta.y > 0 ? step : -step) - root.from) / (root.to - root.from)) * root.width)
        }
    }
    FocusRing { radius: root.th / 2 + 5 }
}
