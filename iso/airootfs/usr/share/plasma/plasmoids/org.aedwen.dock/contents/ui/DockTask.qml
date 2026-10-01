// One app in the dock: tinted tile, a running dot that widens into a pill
// for the focused app, the window title as tooltip, and a context menu.
// Drag to reorder.
import QtQuick
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.extras as PlasmaExtras
import org.kde.taskmanager as TaskManager
import org.aedwen.ui

PlasmaCore.ToolTipArea {
    id: task
    required property var model
    required property int index
    required property TaskManager.TasksModel tasks
    required property var taskActions
    property int cell: 52

    readonly property bool running: !model.IsLauncher && !model.IsStartup
    readonly property bool focused: model.IsActive === true
    readonly property url launcherUrl: model.LauncherUrlWithoutIcon || ""
    width: cell
    height: cell
    mainText: model.AppName || model.display
    subText: running && model.display !== model.AppName ? model.display : ""
    location: PlasmaCore.Types.Floating

    function modelIndex() { return tasks.makeModelIndex(index) }
    function publishGeometry() {
        const p = task.mapToGlobal(0, 0)
        tasks.requestPublishDelegateGeometry(modelIndex(), Qt.rect(p.x, p.y, width, height), task)
    }
    onXChanged: if (running) publishGeometry()
    Component.onCompleted: if (running) publishGeometry()

    Rectangle {
        anchors.fill: parent
        radius: Theme.rCard - 6
        color: mouse.containsMouse ? Theme.state : "transparent"
        Behavior on color { ColorAnimation { duration: Theme.durShort } }
    }
    AppIcon {
        id: tile
        anchors.centerIn: parent
        source: task.model.decoration
        hovered: mouse.containsMouse
        opacity: task.model.IsStartup ? 0.6 : 1
        scale: mouse.pressed ? 0.94 : 1
        Behavior on scale { NumberAnimation { duration: Theme.durShort; easing.type: Easing.OutBack } }

        // launch feedback
        SequentialAnimation on y {
            running: task.model.IsStartup === true
            loops: Animation.Infinite
            NumberAnimation { to: tile.y - 6; duration: Theme.durMed; easing.type: Easing.OutQuad }
            NumberAnimation { to: tile.y; duration: Theme.durMed; easing.type: Easing.InQuad }
        }
    }
    // attention badge (urgent window)
    Rectangle {
        visible: task.model.IsDemandingAttention === true
        width: 10; height: 10; radius: 5
        color: Theme.err
        anchors.right: tile.right
        anchors.top: tile.top
        anchors.margins: -2
    }
    // running indicator
    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 1
        height: 3
        radius: 2
        width: task.focused ? 16 : 5
        color: task.focused ? Theme.primary : Theme.fgVariant
        opacity: task.running ? 1 : 0
        Behavior on width { NumberAnimation { duration: Theme.dur; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.spring } }
        Behavior on color { ColorAnimation { duration: Theme.durShort } }
        Behavior on opacity { NumberAnimation { duration: Theme.durShort } }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        drag.target: undefined

        property point pressPos
        property bool dragging: false
        onPressed: mouse => { pressPos = Qt.point(mouse.x, mouse.y); dragging = false }
        onPositionChanged: mouse => {
            if (!(pressedButtons & Qt.LeftButton)) return
            if (!dragging && Math.abs(mouse.x - pressPos.x) + Math.abs(mouse.y - pressPos.y) > 12)
                dragging = true
            if (dragging) {
                // reorder: move this entry to the slot under the cursor
                const p = mapToItem(task.parent, mouse.x, mouse.y)
                const target = task.parent.childAt(p.x, p.y)
                if (target && target !== task && target.index !== undefined && target.tasks === task.tasks)
                    task.tasks.move(task.index, target.index)
            }
        }
        onReleased: dragging = false
        onClicked: mouse => {
            if (dragging) return
            if (mouse.button === Qt.RightButton) {
                menu.open(mouse.x, mouse.y)
            } else if (mouse.button === Qt.MiddleButton) {
                task.tasks.requestNewInstance(task.modelIndex())
            } else {
                task.taskActions.activate(task.index, mouse.modifiers)
            }
        }
    }

    PlasmaExtras.Menu {
        id: menu
        visualParent: task
        placement: PlasmaExtras.Menu.TopPosedLeftAlignedPopup

        PlasmaExtras.MenuItem {
            text: task.taskActions.isPinned(task.launcherUrl) ? i18n("Unpin from Dock") : i18n("Pin to Dock")
            icon: "pin"
            visible: task.launcherUrl.toString() !== ""
            onClicked: task.taskActions.togglePin(task.launcherUrl)
        }
        PlasmaExtras.MenuItem {
            text: i18n("New Window")
            icon: "window-new"
            visible: task.model.CanLaunchNewInstance !== false
            onClicked: task.tasks.requestNewInstance(task.modelIndex())
        }
        PlasmaExtras.MenuItem {
            separator: true
            visible: task.running
        }
        PlasmaExtras.MenuItem {
            text: task.model.IsMinimized ? i18n("Restore") : i18n("Minimize")
            icon: "window-minimize"
            visible: task.running && task.model.IsMinimizable !== false
            onClicked: task.tasks.requestToggleMinimized(task.modelIndex())
        }
        PlasmaExtras.MenuItem {
            text: task.model.IsGroupParent ? i18n("Close All Windows") : i18n("Close")
            icon: "window-close"
            visible: task.running && task.model.IsClosable !== false
            onClicked: task.tasks.requestClose(task.modelIndex())
        }
    }
}
