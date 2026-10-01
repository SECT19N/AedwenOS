// Quick-settings tile: symbol over a label (and optional detail line).
// On = primary fill and a rounder square; off = surface-container-high and a
// tighter corner, so toggling morphs the shape (M3E). Click toggles;
// right-click or the chevron (when `configurable`) asks for details.
import QtQuick

Rectangle {
    id: root
    property string icon
    property string label
    property string detail
    property bool active: false
    property bool configurable: false
    property bool busy: false
    signal toggled()
    signal configureRequested()

    readonly property color fg: active ? Theme.primaryFg : Theme.fg

    implicitWidth: 104
    implicitHeight: 76
    radius: active ? Theme.rCard : Theme.rInner + 4
    color: active ? Theme.primary : Theme.scHigh
    opacity: enabled ? 1 : 0.45
    Behavior on radius { NumberAnimation { duration: Theme.dur; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.spring } }
    Behavior on color { ColorAnimation { duration: Theme.durShort } }

    StateLayer { area: mouse; tint: root.fg }

    Sym {
        id: glyph
        name: root.icon
        fill: root.active ? 1 : 0
        color: root.fg
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.margins: 12
    }
    MorphShape {
        visible: root.busy
        running: root.busy
        color: root.fg
        width: 18
        height: 18
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 12
    }
    Sym {
        visible: root.configurable && !root.busy
        name: "chevron_right"
        size: 18
        color: root.fg
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 10
    }
    Column {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 12
        spacing: 0
        Label {
            width: parent.width
            text: root.label
            role: "label"
            font.weight: Font.DemiBold
            color: root.fg
        }
        Label {
            visible: root.detail !== ""
            width: parent.width
            text: root.detail
            role: "caption"
            color: root.fg
            opacity: 0.8
        }
    }
    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        enabled: root.enabled
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton
                    || (root.configurable && mouse.x > width - 36 && mouse.y < 36))
                root.configureRequested()
            else
                root.toggled()
        }
    }
}
