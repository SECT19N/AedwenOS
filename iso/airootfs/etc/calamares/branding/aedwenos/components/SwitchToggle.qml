// 52x32 Material switch: filled primary track + 24px knob when on,
// outlined track + 16px knob when off.
import QtQuick
import ".."

Rectangle {
    id: root
    property bool checked: false
    signal toggled(bool checked)

    width: 52
    height: 32
    radius: 16
    color: checked ? Theme.primary : Theme.scHighest
    border.width: checked ? 0 : 2
    border.color: Theme.outline
    Behavior on color { ColorAnimation { duration: 200 } }

    Rectangle {
        readonly property int size: root.checked ? 24 : 16
        width: size
        height: size
        radius: size / 2
        color: root.checked ? Theme.primaryFg : Theme.outline
        anchors.verticalCenter: parent.verticalCenter
        x: root.checked ? root.width - width - 4 : 8
        Behavior on x { NumberAnimation { duration: 260; easing.type: Easing.OutBack } }
        Behavior on width { NumberAnimation { duration: 200 } }
    }
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: { root.checked = !root.checked; root.toggled(root.checked) }
    }
}
