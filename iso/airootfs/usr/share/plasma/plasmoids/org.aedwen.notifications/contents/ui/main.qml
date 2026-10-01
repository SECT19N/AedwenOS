// AedwenOS notification centre (Desktop design: NOTIFICATION CENTER).
//
// Reads KDE's notification history (NotificationManager) -- pop-ups are
// still shown by KDE's own notifications applet, kept hidden in the system
// tray, so every app's notifications behave as usual and land here.
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.notificationmanager as NotificationManager
import org.aedwen.ui

PlasmoidItem {
    id: root
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    Plasmoid.icon: "notifications"
    preferredRepresentation: compactRepresentation
    switchWidth: 300
    switchHeight: 300
    toolTipMainText: i18n("Notifications")
    toolTipSubText: history.unreadNotificationsCount > 0
                    ? i18np("%1 unread notification", "%1 unread notifications", history.unreadNotificationsCount)
                    : dnd ? i18n("Do not disturb is on") : i18n("No unread notifications")

    NotificationManager.Settings { id: settings; live: true }
    readonly property bool dnd: settings.notificationsInhibitedUntil > new Date()
                                || settings.notificationsInhibitedByApplication

    NotificationManager.Notifications {
        id: history
        showExpired: true
        showDismissed: true
        showJobs: false
        sortMode: NotificationManager.Notifications.SortByDate
        groupMode: NotificationManager.Notifications.GroupDisabled
        urgencies: NotificationManager.Notifications.LowUrgency
                   | NotificationManager.Notifications.NormalUrgency
                   | NotificationManager.Notifications.CriticalUrgency
    }
    onExpandedChanged: () => { if (!root.expanded) history.lastRead = new Date() }

    function setDnd(on) {
        if (on) {
            const d = new Date(); d.setFullYear(d.getFullYear() + 1)
            settings.notificationsInhibitedUntil = d
        } else {
            settings.notificationsInhibitedUntil = new Date(0)
            settings.revokeApplicationInhibitions()
        }
        settings.save()
    }

    compactRepresentation: Item {
        Layout.minimumWidth: button.implicitWidth
        Layout.preferredWidth: button.implicitWidth
        PanelButton {
            id: button
            anchors.centerIn: parent
            active: root.expanded
            padding: 9
            onClicked: mouse => {
                if (mouse.button === Qt.MiddleButton) root.setDnd(!root.dnd)
                else root.expanded = !root.expanded
            }
            Sym {
                anchors.verticalCenter: parent.verticalCenter
                name: root.dnd ? "notifications_paused" : "notifications"
                fill: history.unreadNotificationsCount > 0 ? 1 : 0
                size: 18
                color: root.expanded ? Theme.secCFg : Theme.fg
            }
        }
        Rectangle {
            visible: history.unreadNotificationsCount > 0 && !root.dnd
            width: 7; height: 7; radius: 4
            color: Theme.primary
            x: button.x + button.width - 12
            y: button.y + 5
        }
    }

    fullRepresentation: NotificationCenter { center: root; model: history }
}
