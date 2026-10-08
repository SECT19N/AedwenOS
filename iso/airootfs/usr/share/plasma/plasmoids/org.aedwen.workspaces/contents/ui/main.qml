// Workspace dots (Desktop design: top bar). One dot per virtual desktop:
// the current one stretches into a primary pill, desktops with windows are
// brighter. Click switches, scrolling cycles.
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.taskmanager as TaskManager
import org.aedwen.ui
import org.aedwen.shell

PlasmoidItem {
    id: root
    preferredRepresentation: fullRepresentation
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground

    TaskManager.VirtualDesktopInfo { id: desktops }
    TaskManager.ActivityInfo { id: activityInfo }
    TaskManager.TasksModel {
        id: tasks
        groupMode: TaskManager.TasksModel.GroupDisabled
        filterByActivity: true
        activity: activityInfo.currentActivity
    }
    // desktop id -> has windows
    readonly property var occupied: {
        const used = {}
        for (let i = 0; i < tasks.count; ++i) {
            const ds = tasks.data(tasks.index(i, 0), TaskManager.AbstractTasksModel.VirtualDesktops) || []
            for (const d of ds) used[d] = true
        }
        return used
    }

    fullRepresentation: Item {
        id: area
        // dot size follows the panel thickness (8 px at the default 32)
        readonly property int dot: Math.max(6, Math.round(height / 4))
        Layout.minimumWidth: dots.implicitWidth + 2 * dot
        Layout.preferredWidth: Layout.minimumWidth
        Layout.maximumWidth: Layout.minimumWidth

        Row {
            id: dots
            anchors.centerIn: parent
            spacing: Math.round(area.dot * 0.62)
            Repeater {
                model: desktops.desktopIds
                delegate: Rectangle {
                    required property int index
                    required property var modelData
                    readonly property bool current: modelData === desktops.currentDesktop
                    anchors.verticalCenter: parent.verticalCenter
                    height: area.dot
                    width: current ? Math.round(area.dot * 2.75) : area.dot
                    radius: area.dot / 2
                    color: current ? Theme.primary
                         : root.occupied[modelData] ? Theme.fgVariant : Theme.outline
                    opacity: current || mouse.containsMouse ? 1 : 0.8
                    Behavior on width { NumberAnimation { duration: Theme.dur; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.spring } }
                    Behavior on color { ColorAnimation { duration: Theme.durShort } }

                    PlasmaCore.ToolTipArea {
                        anchors.fill: parent
                        anchors.margins: -6
                        mainText: desktops.desktopNames[index] || i18n("Desktop %1", index + 1)
                        MouseArea {
                            id: mouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Shell.switchDesktop(index + 1)
                        }
                    }
                }
            }
        }
        WheelHandler {
            onWheel: event => {
                const ids = desktops.desktopIds
                const cur = ids.indexOf(desktops.currentDesktop)
                const next = (cur + (event.angleDelta.y < 0 ? 1 : -1) + ids.length) % ids.length
                Shell.switchDesktop(next + 1)
            }
        }
    }
}
