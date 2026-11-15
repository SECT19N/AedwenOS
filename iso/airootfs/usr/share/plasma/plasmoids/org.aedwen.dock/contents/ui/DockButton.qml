// Fixed dock entries (launcher, trash): a neutral tile with a symbol.
import QtQuick
import org.kde.plasma.core as PlasmaCore
import org.aedwen.ui

PlasmaCore.ToolTipArea {
    id: root
    property string symbol
    property string label
    property int cell: 52
    // the launcher: primary container; anything else (trash): neutral
    property bool accent: false
    signal activated()

    width: cell
    height: cell
    mainText: label
    location: PlasmaCore.Types.Floating

    Rectangle {
        anchors.fill: parent
        radius: Math.round(root.cell * 0.27)
        color: mouse.containsMouse ? Theme.state : "transparent"
        Behavior on color { ColorAnimation { duration: Theme.durShort } }
    }
    AppIcon {
        anchors.centerIn: parent
        symbol: root.symbol
        size: Math.round(root.cell * 0.77)
        hovered: mouse.containsMouse
        symbolTile: root.accent ? Theme.pc : Theme.scHighest
        symbolColor: root.accent ? Theme.pcFg : Theme.fgVariant
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
