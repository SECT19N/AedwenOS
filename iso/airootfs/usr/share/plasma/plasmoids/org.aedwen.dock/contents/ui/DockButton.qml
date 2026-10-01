// Fixed dock entries (launcher, trash): a neutral tile with a symbol.
import QtQuick
import org.kde.plasma.core as PlasmaCore
import org.aedwen.ui

PlasmaCore.ToolTipArea {
    id: root
    property string symbol
    property string label
    signal activated()

    width: 52
    height: 52
    mainText: label
    location: PlasmaCore.Types.Floating

    Rectangle {
        anchors.fill: parent
        radius: Theme.rCard - 6
        color: mouse.containsMouse ? Theme.state : "transparent"
        Behavior on color { ColorAnimation { duration: Theme.durShort } }
    }
    AppIcon {
        anchors.centerIn: parent
        symbol: root.symbol
        hovered: mouse.containsMouse
        scale: mouse.pressed ? 0.94 : 1
        Behavior on scale { NumberAnimation { duration: Theme.durShort; easing.type: Easing.OutBack } }
    }
    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.activated()
    }
}
