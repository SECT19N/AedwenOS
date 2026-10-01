// A top-bar item: pill-shaped hover/press layer, secondary-container fill
// while its popup is open (`active`). Put any content inside.
import QtQuick

Rectangle {
    id: root
    property bool active: false
    property int padding: 10
    default property alias content: row.data
    readonly property alias containsMouse: mouse.containsMouse
    signal clicked(var mouse)

    implicitWidth: row.implicitWidth + padding * 2
    implicitHeight: 32
    radius: height / 2
    color: active ? Theme.secC : "transparent"
    Behavior on color { ColorAnimation { duration: Theme.durShort } }

    StateLayer { area: mouse; tint: root.active ? Theme.secCFg : Theme.fg }
    Row {
        id: row
        anchors.centerIn: parent
        spacing: 8
    }
    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        onClicked: mouse => root.clicked(mouse)
    }
}
