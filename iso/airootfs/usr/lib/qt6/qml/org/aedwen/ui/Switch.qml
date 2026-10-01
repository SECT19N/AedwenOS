// Material switch, 52x32 (or 44x26 compact): filled primary track and a
// large knob when on, outlined track and a small knob when off.
import QtQuick

Rectangle {
    id: root
    property bool checked: false
    property bool compact: false
    signal toggled(bool checked)

    implicitWidth: compact ? 44 : 52
    implicitHeight: compact ? 26 : 32
    radius: height / 2
    color: checked ? Theme.primary : Theme.scHighest
    border.width: checked ? 0 : 2
    border.color: Theme.outline
    opacity: enabled ? 1 : 0.45
    Behavior on color { ColorAnimation { duration: Theme.durShort } }

    Rectangle {
        readonly property real size: root.checked || mouse.pressed ? root.height - 8 : root.height / 2
        width: size
        height: size
        radius: size / 2
        color: root.checked ? Theme.primaryFg : Theme.outline
        anchors.verticalCenter: parent.verticalCenter
        x: root.checked ? root.width - width - 4 : (root.height - height) / 2
        Behavior on x { NumberAnimation { duration: Theme.durMed; easing.type: Easing.OutBack } }
        Behavior on width { NumberAnimation { duration: Theme.durShort } }
    }
    MouseArea {
        id: mouse
        anchors.fill: parent
        enabled: root.enabled
        cursorShape: Qt.PointingHandCursor
        onClicked: { root.checked = !root.checked; root.toggled(root.checked) }
    }
}
