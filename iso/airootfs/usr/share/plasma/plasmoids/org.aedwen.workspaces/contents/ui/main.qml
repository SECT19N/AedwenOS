// Workspace pills (Desktop design: top bar). One numbered 16 px pill per
// virtual desktop, 5 px apart: the current one is a wider primary pill,
// desktops with windows have brighter numbers than empty ones. Click
// switches, scrolling cycles, middle-click removes an empty desktop, and the
// trailing + pill adds one. Overview stays on the top-left hot corner and
// Meta+W.
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
    // design: --fg2 / --fg3 (72 % / 50 % of the text colour)
    readonly property color usedColor: Theme.alpha(Theme.fg, 0.72)
    readonly property color emptyColor: Theme.alpha(Theme.fg, 0.5)

    fullRepresentation: Item {
        id: area
        readonly property int pill: 16
        Layout.minimumWidth: dots.implicitWidth + pill
        Layout.preferredWidth: Layout.minimumWidth
        Layout.maximumWidth: Layout.minimumWidth

        Row {
            id: dots
            anchors.centerIn: parent
            spacing: 5
            Repeater {
                model: desktops.desktopIds
                delegate: Rectangle {
                    required property int index
                    required property var modelData
                    readonly property bool current: modelData === desktops.currentDesktop
                    anchors.verticalCenter: parent.verticalCenter
                    height: area.pill
                    width: current ? 28 : Math.max(area.pill, number.implicitWidth + 8)
                    radius: area.pill / 2
                    color: current ? Theme.primary : Theme.alpha(Theme.fg, mouse.containsMouse ? 0.18 : 0.12)
                    Behavior on width { NumberAnimation { duration: Theme.dur; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.spring } }
                    Behavior on color { ColorAnimation { duration: Theme.durShort } }

                    Text {
                        id: number
                        anchors.centerIn: parent
                        text: index + 1
                        font.family: Theme.font
                        font.pixelSize: 10
                        font.weight: Font.DemiBold
                        font.features: { "tnum": 1 }
                        color: current ? Theme.primaryFg
                             : root.occupied[modelData] || mouse.containsMouse ? root.usedColor : root.emptyColor
                    }

                    PlasmaCore.ToolTipArea {
                        anchors.fill: parent
                        anchors.margins: -2
                        mainText: desktops.desktopNames[index] || i18n("Desktop %1", index + 1)
                        subText: !current && !root.occupied[modelData] && desktops.numberOfDesktops > 1
                                 ? i18n("Middle-click to remove") : ""
                        MouseArea {
                            id: mouse
                            anchors.fill: parent
                            hoverEnabled: true
                            acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                            cursorShape: Qt.PointingHandCursor
                            onClicked: ev => {
                                if (ev.button === Qt.LeftButton)
                                    Shell.switchDesktop(index + 1)
                                else if (!current && !root.occupied[modelData] && desktops.numberOfDesktops > 1)
                                    Shell.removeDesktop(modelData)
                            }
                        }
                    }
                }
            }
            // new desktop
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                height: area.pill
                width: area.pill
                radius: area.pill / 2
                color: Theme.alpha(Theme.fg, addMouse.containsMouse ? 0.18 : 0.12)
                Behavior on color { ColorAnimation { duration: Theme.durShort } }
                Sym {
                    anchors.centerIn: parent
                    name: "add"
                    size: 12
                    weight: 600
                    color: addMouse.containsMouse ? Theme.fg : root.usedColor
                }

                PlasmaCore.ToolTipArea {
                    anchors.fill: parent
                    anchors.margins: -2
                    mainText: i18n("New desktop")
                    MouseArea {
                        id: addMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.switchToNew = desktops.numberOfDesktops + 1
                            Shell.addDesktop(desktops.numberOfDesktops)
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

    // After + : switch to the new desktop once KWin has created it.
    property int switchToNew: 0
    Connections {
        target: desktops
        function onNumberOfDesktopsChanged() {
            if (root.switchToNew > 0 && desktops.numberOfDesktops >= root.switchToNew) {
                Shell.switchDesktop(root.switchToNew)
                root.switchToNew = 0
            }
        }
    }
}
