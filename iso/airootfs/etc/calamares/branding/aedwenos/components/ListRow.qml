// Selectable list row (design: location / keyboard lists). Selected rows
// use the secondary container and show a trailing check.
import QtQuick
import ".."

Rectangle {
    id: root
    property string title
    property string subtitle
    property bool selected: false
    signal clicked()

    width: ListView.view ? ListView.view.width : 300
    height: subtitle ? 52 : 44
    radius: Theme.rInner
    color: selected ? Theme.secC : mouse.containsMouse ? Theme.state : "transparent"

    Column {
        anchors.left: parent.left
        anchors.right: check.left
        anchors.leftMargin: 12
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        spacing: 1
        Text {
            width: parent.width
            text: root.title
            elide: Text.ElideRight
            color: root.selected ? Theme.secCFg : Theme.fg
            font.family: Theme.font
            font.pixelSize: 14
            font.weight: root.selected ? Font.DemiBold : Font.Normal
        }
        Text {
            visible: root.subtitle !== ""
            width: parent.width
            text: root.subtitle
            elide: Text.ElideRight
            color: root.selected ? Theme.secCFg : Theme.fgVariant
            opacity: 0.85
            font.family: Theme.font
            font.pixelSize: 12
        }
    }
    Sym {
        id: check
        name: "check"
        opacity: root.selected ? 1 : 0
        color: Theme.secCFg
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
    }
    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
