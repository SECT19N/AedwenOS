// Workspace pills (Desktop design: top bar). One numbered 26 px pill per
// virtual desktop, 4 px apart, on surface-container-highest: the current one
// is a 40 px primary pill, desktops with windows have full-strength numbers,
// empty ones muted. Past six desktops the others shrink to 12 px dots
// (outline colour when they hold windows). Click switches, scrolling cycles,
// right- or middle-click removes an empty desktop, and the trailing dashed +
// adds one. Overview stays on the top-left hot corner and Meta+W.
import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
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
    // design: on-surface for desktops with windows, on-surface-variant if empty
    readonly property color usedColor: Theme.fg
    readonly property color emptyColor: Theme.fgVariant
    readonly property bool compact: desktops.numberOfDesktops > 6

    fullRepresentation: Item {
        id: area
        readonly property int pill: 26
        Layout.minimumWidth: dots.implicitWidth + 12
        Layout.preferredWidth: Layout.minimumWidth
        Layout.maximumWidth: Layout.minimumWidth

        Row {
            id: dots
            anchors.centerIn: parent
            spacing: 4
            Repeater {
                model: desktops.desktopIds
                delegate: Rectangle {
                    required property int index
                    required property var modelData
                    readonly property bool current: modelData === desktops.currentDesktop
                    readonly property bool used: !!root.occupied[modelData]
                    readonly property bool dot: root.compact && !current
                    anchors.verticalCenter: parent.verticalCenter
                    height: dot ? 12 : area.pill
                    width: current ? 40 : dot ? 12 : Math.max(area.pill, number.implicitWidth + 12)
                    radius: height / 2
                    color: current ? Theme.primary
                         : dot && used ? Theme.outline
                         : mouse.containsMouse ? Theme.mix(Theme.scHighest, Theme.fg, 0.08) : Theme.scHighest
                    Behavior on width { NumberAnimation { duration: Theme.dur; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.spring } }
                    Behavior on color { ColorAnimation { duration: Theme.durShort } }

                    Text {
                        id: number
                        anchors.centerIn: parent
                        visible: !dot
                        text: index + 1
                        font.family: Theme.font
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                        font.features: { "tnum": 1 }
                        color: current ? Theme.primaryFg
                             : used || mouse.containsMouse ? root.usedColor : root.emptyColor
                    }

                    PlasmaCore.ToolTipArea {
                        anchors.fill: parent
                        anchors.margins: -2
                        mainText: desktops.desktopNames[index] || i18n("Desktop %1", index + 1)
                        subText: !current && !used && desktops.numberOfDesktops > 1
                                 ? i18n("Right-click to remove") : ""
                        MouseArea {
                            id: mouse
                            anchors.fill: parent
                            hoverEnabled: true
                            acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                            cursorShape: Qt.PointingHandCursor
                            onClicked: ev => {
                                if (ev.button === Qt.LeftButton)
                                    Shell.switchDesktop(index + 1)
                                else if (!current && !used && desktops.numberOfDesktops > 1)
                                    Shell.removeDesktop(modelData)
                            }
                        }
                    }
                }
            }
            // new desktop: a dashed outline circle (design)
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                height: area.pill
                width: area.pill
                radius: area.pill / 2
                color: addMouse.containsMouse ? Theme.state : "transparent"
                Behavior on color { ColorAnimation { duration: Theme.durShort } }
                Shape {
                    anchors.fill: parent
                    preferredRendererType: Shape.CurveRenderer
                    ShapePath {
                        strokeColor: Theme.outline
                        strokeWidth: 1
                        strokeStyle: ShapePath.DashLine
                        dashPattern: [3, 2]
                        fillColor: "transparent"
                        PathAngleArc {
                            centerX: area.pill / 2; centerY: area.pill / 2
                            radiusX: area.pill / 2 - 0.5; radiusY: radiusX
                            startAngle: 0; sweepAngle: 360
                        }
                    }
                }
                Sym {
                    anchors.centerIn: parent
                    name: "add"
                    size: 16
                    color: addMouse.containsMouse ? Theme.fg : Theme.fgVariant
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
