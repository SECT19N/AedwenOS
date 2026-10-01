// The focused app's name, bold, next to the global menu (Desktop design:
// top bar). Shows "Desktop" when nothing is focused.
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.taskmanager as TaskManager
import org.aedwen.ui

PlasmoidItem {
    id: root
    preferredRepresentation: fullRepresentation
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground

    TaskManager.VirtualDesktopInfo { id: desktops }
    TaskManager.ActivityInfo { id: activityInfo }
    TaskManager.TasksModel {
        id: tasks
        groupMode: TaskManager.TasksModel.GroupDisabled
        filterByScreen: true
        screenGeometry: Plasmoid.containment.screenGeometry
        filterByVirtualDesktop: true
        virtualDesktop: desktops.currentDesktop
        filterByActivity: true
        activity: activityInfo.currentActivity
    }
    readonly property string appName: {
        const i = tasks.activeTask
        if (!i || !i.valid) return i18n("Desktop")
        return tasks.data(i, TaskManager.AbstractTasksModel.AppName)
            || tasks.data(i, Qt.DisplayRole) || i18n("Desktop")
    }

    fullRepresentation: Item {
        Layout.minimumWidth: label.implicitWidth + 12
        Layout.preferredWidth: Layout.minimumWidth
        Layout.maximumWidth: 260
        Label {
            id: label
            anchors.centerIn: parent
            width: Math.min(implicitWidth, 248)
            text: root.appName
            font.weight: Font.DemiBold
        }
    }
}
