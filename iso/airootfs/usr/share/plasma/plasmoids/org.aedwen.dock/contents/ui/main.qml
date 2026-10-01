// AedwenOS Dock (Desktop design: dock; System Surfaces: M3E tiles).
//
// Every entry comes from TaskManager.TasksModel: pinned launchers (stored in
// the `launchers` config) and whatever is running, grouped per app. Tiles
// use each app's own icon tinted by its colour (org.aedwen.ui AppIcon), so
// any installed app looks right without per-app styling.
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.extras as PlasmaExtras
import org.kde.taskmanager as TaskManager
import org.kde.plasma.private.kicker as Kicker
import org.aedwen.ui
import org.aedwen.shell

PlasmoidItem {
    id: dock

    readonly property bool vertical: Plasmoid.formFactor === PlasmaCore.Types.Vertical
    readonly property int cell: 52

    preferredRepresentation: fullRepresentation
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    Plasmoid.constraintHints: Plasmoid.CanFillArea

    TaskManager.VirtualDesktopInfo { id: desktopInfo }
    TaskManager.ActivityInfo { id: activityInfo }

    TaskManager.TasksModel {
        id: tasksModel
        screenGeometry: Plasmoid.containment.screenGeometry
        activity: activityInfo.currentActivity
        virtualDesktop: desktopInfo.currentDesktop
        filterByVirtualDesktop: Plasmoid.configuration.showOnlyCurrentDesktop
        filterByScreen: Plasmoid.configuration.showOnlyCurrentScreen
        filterByActivity: true
        groupMode: TaskManager.TasksModel.GroupApplications
        groupInline: false
        sortMode: TaskManager.TasksModel.SortManual
        separateLaunchers: false
        hideActivatedLaunchers: true
        launchInPlace: true
        Component.onCompleted: dock.loadLaunchers()
        onLauncherListChanged: dock.saveLaunchers()
    }
    Connections {
        target: Plasmoid.configuration
        function onLaunchersChanged() { dock.loadLaunchers() }
    }

    // Pins whose app isn't installed (e.g. a default pin for an app the
    // user removed) are kept in the config, so they come back if the app is
    // reinstalled, but not shown. Kicker's favourites model is the validator:
    // it drops desktop ids it can't resolve.
    Kicker.SimpleFavoritesModel { id: validator }
    property var hiddenLaunchers: []
    function loadLaunchers() {
        const all = Plasmoid.configuration.launchers
        const prefix = "applications:"
        validator.favorites = all.filter(u => u.startsWith(prefix)).map(u => u.slice(prefix.length))
        const valid = validator.favorites
        const shown = all.filter(u => !u.startsWith(prefix) || valid.indexOf(u.slice(prefix.length)) !== -1)
        hiddenLaunchers = all.filter(u => shown.indexOf(u) === -1)
        if (tasksModel.launcherList.join() !== shown.join())
            tasksModel.launcherList = shown
    }
    function saveLaunchers() {
        const merged = tasksModel.launcherList.concat(hiddenLaunchers)
        if (merged.join() !== Plasmoid.configuration.launchers.join())
            Plasmoid.configuration.launchers = merged
    }
    TaskActions { id: actions; model: tasksModel }

    fullRepresentation: Item {
        Layout.minimumWidth: dock.vertical ? dock.cell : row.implicitWidth
        Layout.preferredWidth: Layout.minimumWidth
        Layout.maximumWidth: Layout.minimumWidth
        Layout.minimumHeight: dock.vertical ? row.implicitHeight : dock.cell
        Layout.preferredHeight: Layout.minimumHeight
        Layout.maximumHeight: Layout.minimumHeight

        Grid {
            id: row
            anchors.centerIn: parent
            flow: dock.vertical ? Grid.TopToBottom : Grid.LeftToRight
            rows: dock.vertical ? -1 : 1
            columns: dock.vertical ? 1 : -1
            spacing: 4
            verticalItemAlignment: Grid.AlignVCenter
            horizontalItemAlignment: Grid.AlignHCenter

            DockButton {
                visible: Plasmoid.configuration.showLauncherButton
                symbol: "apps"
                label: i18n("Applications")
                onActivated: Shell.openLauncher()
            }

            Repeater {
                id: taskRepeater
                model: tasksModel
                delegate: DockTask {
                    tasks: tasksModel
                    taskActions: actions
                    cell: dock.cell
                }
            }

            Rectangle {      // separator
                visible: Plasmoid.configuration.showTrash
                width: dock.vertical ? 28 : 1
                height: dock.vertical ? 1 : 28
                color: Theme.outlineV
            }
            DockButton {
                visible: Plasmoid.configuration.showTrash
                symbol: "delete"
                label: i18n("Trash")
                onActivated: Qt.openUrlExternally("trash:/")
            }
        }

        // Drop a .desktop file / app from the launcher to pin it.
        DropArea {
            anchors.fill: parent
            keys: ["text/uri-list"]
            onDropped: drop => {
                for (const url of drop.urls) {
                    const s = url.toString()
                    if (s.endsWith(".desktop") || s.startsWith("applications:"))
                        tasksModel.requestAddLauncher(url)
                }
            }
        }
    }
}
