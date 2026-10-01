// Outlined pill dropdown with a leading icon (design: welcome language
// picker). Opens a popup list on the sc-high surface.
import QtQuick
import QtQuick.Controls
import ".."

Rectangle {
    id: root
    property var model
    property string textRole: ""
    property int currentIndex: -1
    property string icon
    property string currentText
    signal activated(int index)

    width: 300
    height: 44
    radius: height / 2
    color: mouse.containsMouse ? Theme.state : "transparent"
    border.width: popup.visible ? 2 : 1
    border.color: popup.visible ? Theme.primary : Theme.outline

    Row {
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 10
        spacing: 10
        Sym {
            visible: root.icon !== ""
            name: root.icon
            anchors.verticalCenter: parent.verticalCenter
        }
        Text {
            width: parent.width - 30 - (root.icon ? 30 : 0)
            anchors.verticalCenter: parent.verticalCenter
            text: root.currentText
            elide: Text.ElideRight
            color: Theme.fg
            font.family: Theme.font
            font.pixelSize: 14
        }
        Sym {
            name: "expand_more"
            anchors.verticalCenter: parent.verticalCenter
            rotation: popup.visible ? 180 : 0
            Behavior on rotation { NumberAnimation { duration: 200 } }
        }
    }
    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: popup.visible ? popup.close() : popup.open()
    }

    Popup {
        id: popup
        y: root.height + 6
        width: root.width
        height: Math.min(list.contentHeight + 8, 320)
        padding: 4
        background: Rectangle { radius: 16; color: Theme.scHigh }
        onOpened: list.positionViewAtIndex(Math.max(0, root.currentIndex), ListView.Center)

        ListView {
            id: list
            anchors.fill: parent
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            model: root.model
            spacing: 2
            delegate: ListRow {
                width: list.width
                title: root.textRole ? model[root.textRole] : modelData
                selected: index === root.currentIndex
                onClicked: {
                    root.currentIndex = index
                    root.activated(index)
                    popup.close()
                }
            }
        }
    }
}
