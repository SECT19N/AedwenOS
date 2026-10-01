// Popup: 3-column tile grid, sliders, then battery status and a gear that
// opens System Settings.
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.aedwen.ui
import org.aedwen.shell

Item {
    id: popup
    Layout.minimumWidth: 356
    Layout.preferredWidth: 356
    Layout.minimumHeight: col.implicitHeight + 16
    Layout.preferredHeight: col.implicitHeight + 16

    ColumnLayout {
        id: col
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 8
        spacing: 16

        GridLayout {
            Layout.fillWidth: true
            columns: 3
            rowSpacing: 8
            columnSpacing: 8
            Repeater {
                model: Plasmoid.configuration.tiles
                Loader {
                    id: tileLoader
                    required property string modelData
                    source: Qt.resolvedUrl("tiles/" + modelData + ".qml")
                    readonly property bool shown: status === Loader.Ready && item.available
                    visible: shown
                    Layout.fillWidth: true
                    Layout.preferredHeight: 76
                    Layout.preferredWidth: 1
                    onStatusChanged: if (status === Loader.Error)
                        console.warn("aedwen quicksettings: tile", modelData, "failed to load")
                }
            }
        }

        Repeater {
            model: Plasmoid.configuration.sliders
            Loader {
                required property string modelData
                Layout.fillWidth: true
                source: Qt.resolvedUrl("sliders/" + modelData + ".qml")
                visible: status === Loader.Ready && item.available
            }
        }

        Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Theme.outlineV }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            Loader {
                id: battery
                source: Qt.resolvedUrl("indicators/Battery.qml")
                visible: status === Loader.Ready && item.shown
                onLoaded: { item.color = Theme.fgVariant; item.showPercent = false }
            }
            Label {
                Layout.fillWidth: true
                visible: battery.visible
                text: battery.item ? battery.item.summary : ""
                color: Theme.fgVariant
                role: "label"
            }
            Item { Layout.fillWidth: true; visible: !battery.visible }
            IconButton {
                icon: "settings"
                onClicked: Shell.openSettings("")
            }
        }
    }
}
