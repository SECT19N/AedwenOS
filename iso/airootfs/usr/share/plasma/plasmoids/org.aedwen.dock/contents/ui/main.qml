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
import org.kde.plasma.plasma5support as P5Support
import org.aedwen.ui
import org.aedwen.shell

PlasmoidItem {
    id: dock

    readonly property bool vertical: Plasmoid.formFactor === PlasmaCore.Types.Vertical

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

    // "Pin to Dock" from the launcher's menus
    Connections {
        target: Shell
        function onPinToDockRequested(desktopId) {
            const url = "applications:" + desktopId
            if (!actions.isPinned(url))
                tasksModel.requestAddLauncher(url)
        }
    }

    // Opens the trash in Dolphin directly. Qt.openUrlExternally("trash:/")
    // goes through the scheme-handler lookup, which only accepts apps that
    // declare x-scheme-handler/trash (Dolphin doesn't), so it asked "which
    // app?" instead.
    P5Support.DataSource {
        id: runner
        engine: "executable"
        connectedSources: []
        onNewData: (source, data) => disconnectSource(source)
    }

    fullRepresentation: Item {
        id: area
        // One square cell per entry, as thick as the panel lets it be (52 px
        // in the default 66 px dock), so resizing the dock resizes the
        // icons. Only the length is constrained; the thickness is the
        // panel's.
        readonly property int cell: Math.max(24, Math.round(dock.vertical ? width : height))
        Layout.minimumWidth: dock.vertical ? -1 : row.implicitWidth
        Layout.preferredWidth: dock.vertical ? -1 : row.implicitWidth
        Layout.maximumWidth: dock.vertical ? Infinity : row.implicitWidth
        Layout.minimumHeight: dock.vertical ? row.implicitHeight : -1
        Layout.preferredHeight: dock.vertical ? row.implicitHeight : -1
        Layout.maximumHeight: dock.vertical ? row.implicitHeight : Infinity

        Grid {
            id: row
            anchors.centerIn: parent
            flow: dock.vertical ? Grid.TopToBottom : Grid.LeftToRight
            rows: dock.vertical ? -1 : 1
            columns: dock.vertical ? 1 : -1
            spacing: Math.round(area.cell / 13)
            verticalItemAlignment: Grid.AlignVCenter
            horizontalItemAlignment: Grid.AlignHCenter

            DockButton {
                visible: Plasmoid.configuration.showLauncherButton
                cell: area.cell
                symbol: "apps"
                accent: true
                label: i18n("Applications")
                onActivated: Shell.openLauncher()
            }

            Repeater {
                id: taskRepeater
                model: tasksModel
                delegate: DockTask {
                    tasks: tasksModel
                    taskActions: actions
                    cell: area.cell
                }
            }

            Rectangle {      // separator
                visible: Plasmoid.configuration.showTrash
                width: dock.vertical ? Math.round(area.cell * 0.54) : 1
                height: dock.vertical ? 1 : Math.round(area.cell * 0.54)
                color: Theme.outlineV
            }
            DockButton {
                visible: Plasmoid.configuration.showTrash
                cell: area.cell
                symbol: "delete"
                label: i18n("Trash")
                onActivated: runner.connectSource("dolphin trash:/")
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
