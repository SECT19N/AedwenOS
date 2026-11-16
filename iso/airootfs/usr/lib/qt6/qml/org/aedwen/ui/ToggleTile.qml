// Quick-settings tile (Desktop design: QUICK SETTINGS). A 68 px row: filled
// symbol, then name and detail line, then a chevron when the tile has a
// details page. On = primary; off = surface-container-highest. Expressive
// tiles morph to a full pill when on (20 px corners when off); baseline
// tiles keep 20 px.
//
// Click toggles. Holding the tile for 480 ms (or right-click) asks for its
// details when `configurable`; the press shrinks it to 95 % meanwhile.
// A tile whose service or hardware is missing stays in place, greyed out,
// with `unavailableText` as its detail line.
import QtQuick

Rectangle {
    id: root
    property string icon
    property string label
    property string detail
    property bool active: false
    property bool configurable: false
    // the chevron: design shows it only on tiles with a details page
    property bool showChevron: configurable
    property bool busy: false
    property bool available: true
    property string unavailableText: qsTr("Unavailable")
    readonly property bool usable: enabled && available
    readonly property bool on: active && available
    signal toggled()
    signal configureRequested()

    readonly property color fg: on ? Theme.primaryFg : Theme.fg

    implicitWidth: 160
    implicitHeight: 68
    radius: on && Theme.expressive ? height / 2 : 20
    color: on ? Theme.primary : Theme.scHighest
    opacity: usable ? 1 : 0.38
    scale: mouse.pressed && !mouse.longFired ? 0.95 : 1
    Behavior on radius { NumberAnimation { duration: Theme.dur; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.morphEasing } }
    Behavior on color { ColorAnimation { duration: Theme.durShort } }
    // design: 450 ms into the press, 200 ms back out
    Behavior on scale {
        NumberAnimation {
            duration: Theme.animate ? (mouse.pressed ? 450 : 200) : 0
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Theme.morphEasing
        }
    }

    StateLayer { area: mouse; tint: root.fg }

    Row {
        anchors.fill: parent
        anchors.leftMargin: 14
        anchors.rightMargin: 10
        spacing: 12

        Item {
            width: 22
            height: parent.height
            Sym {
                anchors.centerIn: parent
                visible: !root.busy
                name: root.icon
                size: 22
                fill: 1
                color: root.fg
            }
            MorphShape {
                anchors.centerIn: parent
                visible: root.busy
                running: root.busy
                color: root.fg
                width: 22
                height: 22
            }
        }
        Column {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - 22 - 12 - (chevron.visible ? chevron.width + 12 : 0)
            spacing: 0
            Label {
                width: parent.width
                text: root.label
                font.pixelSize: 14
                font.weight: Font.DemiBold
                color: root.fg
            }
            Label {
                visible: text !== ""
                width: parent.width
                text: root.available ? root.detail : root.unavailableText
                font.pixelSize: 12
                color: root.fg
                opacity: 0.8
            }
        }
        Sym {
            id: chevron
            anchors.verticalCenter: parent.verticalCenter
            visible: root.showChevron && root.available
            name: "chevron_right"
            size: 20
            color: root.fg
            opacity: 0.7
        }
    }

    MouseArea {
        id: mouse
        property bool longFired: false
        anchors.fill: parent
        hoverEnabled: true
        enabled: root.usable
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        pressAndHoldInterval: 480
        onPressed: mouse => longFired = false
        onPressAndHold: mouse => {
            if (mouse.button === Qt.LeftButton && root.configurable) {
                longFired = true
                root.configureRequested()
            }
        }
        onClicked: mouse => {
            if (longFired)
                return
            if (mouse.button === Qt.RightButton) {
                if (root.configurable) root.configureRequested()
            } else {
                root.toggled()
            }
        }
    }
}
