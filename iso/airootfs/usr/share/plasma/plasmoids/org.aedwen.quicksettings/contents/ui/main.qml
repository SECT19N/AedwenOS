// AedwenOS Quick Settings (Desktop design: QUICK SETTINGS).
//
// A small framework rather than a fixed panel: tiles, sliders and the
// top-bar status icons are separate QML files (tiles/, sliders/,
// indicators/) loaded by name from the config. Each talks to one KDE
// service; if that service's QML API is missing or changes in a Plasma
// update, only that one entry disappears instead of the whole widget.
//
// Tile interface (tiles/*.qml, root is Tile.qml):
//   icon, label, detail, available, active, busy, configurable
//   toggle(), configure()
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.aedwen.ui

PlasmoidItem {
    id: root
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    Plasmoid.icon: "settings"
    preferredRepresentation: compactRepresentation
    switchWidth: 300
    switchHeight: 300
    toolTipMainText: i18n("Quick Settings")

    compactRepresentation: Item {
        Layout.minimumWidth: button.implicitWidth
        Layout.preferredWidth: button.implicitWidth
        PanelButton {
            id: button
            anchors.centerIn: parent
            active: root.expanded
            onClicked: mouse => root.expanded = !root.expanded
            Repeater {
                model: ["Network", "Volume", "Battery"]
                Loader {
                    required property string modelData
                    anchors.verticalCenter: parent.verticalCenter
                    source: Qt.resolvedUrl("indicators/" + modelData + ".qml")
                    visible: status === Loader.Ready && item.shown
                    onLoaded: item.color = Qt.binding(() => root.expanded ? Theme.secCFg : Theme.fg)
                }
            }
        }
        // scroll on the indicators changes the volume, like KDE's own tray
        WheelHandler {
            onWheel: event => volumeStep.item && volumeStep.item.step(event.angleDelta.y > 0 ? 5 : -5)
        }
        Loader { id: volumeStep; source: Qt.resolvedUrl("sliders/Volume.qml"); visible: false }
    }

    fullRepresentation: QuickSettingsPopup {}
}
