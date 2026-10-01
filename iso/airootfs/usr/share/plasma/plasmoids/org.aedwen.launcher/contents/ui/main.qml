// AedwenOS Launcher (Desktop design: LAUNCHER).
//
// Data is KDE's own menu: every installed application (Kicker.RootModel),
// pins stored in KActivities (Kicker.KAStatsFavoritesModel), and search
// through KRunner (Kicker.RunnerModel) -- so apps, settings pages, files and
// calculations all show up without anything being listed by hand.
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.private.kicker as Kicker
import org.aedwen.ui

PlasmoidItem {
    id: root

    property Item searchField: null

    Plasmoid.icon: "start-here-kde-symbolic"
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    preferredRepresentation: compactRepresentation
    switchWidth: 400
    switchHeight: 400

    readonly property Kicker.RootModel rootModel: Kicker.RootModel {
        autoPopulate: false
        appletInterface: root
        flat: true
        sorted: true
        showSeparators: false
        showTopLevelItems: true
        showAllApps: true
        showAllAppsCategorized: false
        showRecentApps: false
        showRecentDocs: false
        showPowerSession: false
        showFavoritesPlaceholder: false

        Component.onCompleted: {
            favoritesModel.initForClient("org.aedwen.launcher.favorites")
            if (!Plasmoid.configuration.favoritesSeeded) {
                if (favoritesModel.count < 1)
                    favoritesModel.portOldFavorites(Plasmoid.configuration.defaultFavorites)
                Plasmoid.configuration.favoritesSeeded = true
            }
            refresh()
        }
    }
    readonly property Kicker.RunnerModel runnerModel: Kicker.RunnerModel {
        query: root.searchField ? root.searchField.text : ""
        appletInterface: root
        mergeResults: true
        favoritesModel: root.rootModel.favoritesModel
    }

    compactRepresentation: Item {
        Layout.minimumWidth: button.implicitWidth
        Layout.preferredWidth: button.implicitWidth
        PanelButton {
            id: button
            anchors.centerIn: parent
            active: root.expanded
            padding: 10
            onClicked: root.expanded = !root.expanded
            EagleMark {
                width: 20
                height: 20
                color: root.expanded ? Theme.secCFg : Theme.primary
            }
        }
    }

    fullRepresentation: LauncherPopup {
        launcher: root
    }

    Component.onCompleted: Plasmoid.activationTogglesExpanded = true
}
