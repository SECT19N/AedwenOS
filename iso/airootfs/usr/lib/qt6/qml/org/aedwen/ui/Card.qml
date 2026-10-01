// Tonal container (surface-container by default) with the card radius.
import QtQuick

Rectangle {
    property int padding: 16
    default property alias content: inner.data

    radius: Theme.rCard
    color: Theme.sc
    implicitWidth: inner.childrenRect.width + padding * 2
    implicitHeight: inner.childrenRect.height + padding * 2

    Item {
        id: inner
        anchors.fill: parent
        anchors.margins: parent.padding
    }
}
