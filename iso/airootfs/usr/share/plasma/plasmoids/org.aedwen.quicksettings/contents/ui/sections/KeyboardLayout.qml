// Keyboard layout chip for the Quick Settings footer, in place of KDE's
// tray keyboard-layout indicator: the current layout's short name ("us",
// "de"); click cycles to the next layout. Only shown with 2+ layouts.
import QtQuick
import org.kde.plasma.workspace.keyboardlayout as Keyboards
import org.aedwen.ui

Rectangle {
    id: chip
    Keyboards.KeyboardLayout { id: keyboard }

    readonly property var layouts: keyboard.layoutsList || []
    readonly property bool available: layouts.length > 1
    readonly property var current: layouts[keyboard.layout]

    implicitWidth: row.implicitWidth + 20
    implicitHeight: 32
    radius: height / 2
    color: Theme.scHighest

    StateLayer { area: mouse }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 6
        Sym { name: "keyboard"; size: 18; color: Theme.fgVariant; anchors.verticalCenter: parent.verticalCenter }
        Label {
            anchors.verticalCenter: parent.verticalCenter
            role: "label"
            font.weight: Font.DemiBold
            text: chip.current ? (chip.current.displayName || chip.current.shortName).toUpperCase() : ""
        }
    }
    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: keyboard.switchToNextLayout()
        onWheel: wheel => wheel.angleDelta.y > 0 ? keyboard.switchToPreviousLayout() : keyboard.switchToNextLayout()
    }
}
