// Page title + one-line description, as at the top of each installer step.
import QtQuick
import ".."

Column {
    property string title
    property string description
    spacing: 6
    Text {
        width: parent.width
        text: parent.title
        wrapMode: Text.WordWrap
        color: Theme.fg
        font.family: Theme.font
        font.pixelSize: 28
        font.weight: Font.Bold
    }
    Text {
        width: parent.width
        visible: parent.description !== ""
        text: parent.description
        wrapMode: Text.WordWrap
        color: Theme.fgVariant
        font.family: Theme.font
        font.pixelSize: 14
    }
}
