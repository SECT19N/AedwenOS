// Pill search field (surface-container-highest) with a leading search
// symbol, placeholder and a clear button. Exposes `text`, `input` and
// `accepted()`; arrow keys / Enter are forwarded via `keyPressed`.
import QtQuick

Rectangle {
    id: root
    property alias text: input.text
    property alias input: input
    property string placeholder: "Search"
    signal accepted()
    signal keyPressed(var event)

    implicitWidth: 300
    implicitHeight: 48
    radius: height / 2
    color: Theme.scHighest
    border.width: input.activeFocus ? 2 : 0
    border.color: Theme.primary

    Sym {
        id: lead
        name: "search"
        color: Theme.fgVariant
        anchors.left: parent.left
        anchors.leftMargin: 16
        anchors.verticalCenter: parent.verticalCenter
    }
    TextInput {
        id: input
        anchors.left: lead.right
        anchors.leftMargin: 12
        anchors.right: clear.left
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        color: Theme.fg
        selectionColor: Theme.primary
        selectedTextColor: Theme.primaryFg
        font.family: Theme.font
        font.pixelSize: 15
        clip: true
        onAccepted: root.accepted()
        Keys.onPressed: event => root.keyPressed(event)
        Label {
            visible: !input.text && !input.preeditText
            text: root.placeholder
            color: Theme.fgVariant
            font.pixelSize: 15
            anchors.verticalCenter: parent.verticalCenter
        }
    }
    IconButton {
        id: clear
        icon: "close"
        size: 32
        iconSize: 18
        visible: input.text !== ""
        anchors.right: parent.right
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        onClicked: { input.clear(); input.forceActiveFocus() }
    }
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.IBeamCursor
        onPressed: mouse => { input.forceActiveFocus(); mouse.accepted = false }
        z: -1
    }
}
