// Settings-style row: title + description on the left, switch on the right.
import QtQuick
import ".."

Rectangle {
    id: root
    property string title
    property string description
    property alias checked: toggle.checked
    signal toggled(bool checked)

    implicitHeight: Math.max(64, texts.implicitHeight + 24)
    color: Theme.scLow

    Column {
        id: texts
        anchors.left: parent.left
        anchors.right: toggle.left
        anchors.leftMargin: 16
        anchors.rightMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2
        Text {
            width: parent.width
            text: root.title
            wrapMode: Text.WordWrap
            color: Theme.fg
            font.family: Theme.font
            font.pixelSize: 14
        }
        Text {
            width: parent.width
            visible: root.description !== ""
            text: root.description
            wrapMode: Text.WordWrap
            color: Theme.fgVariant
            font.family: Theme.font
            font.pixelSize: 13
        }
    }
    SwitchToggle {
        id: toggle
        anchors.right: parent.right
        anchors.rightMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        onToggled: (c) => root.toggled(c)
    }
}
