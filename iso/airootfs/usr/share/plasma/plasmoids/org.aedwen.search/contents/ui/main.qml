// Search pill for the top bar: "search  Alt Space" -- opens KRunner.
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.aedwen.ui
import org.aedwen.shell

PlasmoidItem {
    preferredRepresentation: fullRepresentation
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground

    fullRepresentation: Item {
        Layout.minimumWidth: button.implicitWidth
        Layout.preferredWidth: button.implicitWidth
        PanelButton {
            id: button
            anchors.centerIn: parent
            onClicked: Shell.openSearch("")
            Sym { name: "search"; size: 18; color: Theme.fgVariant; anchors.verticalCenter: parent.verticalCenter }
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                implicitWidth: keys.implicitWidth + 10
                implicitHeight: 18
                radius: 5
                color: "transparent"
                border.width: 1
                border.color: Theme.outlineV
                Label {
                    id: keys
                    anchors.centerIn: parent
                    text: i18nc("keyboard shortcut", "Alt Space")
                    font.family: Theme.mono
                    font.pixelSize: 10
                    color: Theme.fgVariant
                }
            }
        }
    }
}
