// Focus = KDE's Do Not Disturb.
import QtQuick
import org.kde.notificationmanager as NotificationManager
import ".."

Tile {
    NotificationManager.Settings { id: settings; live: true }
    readonly property bool dnd: settings.notificationsInhibitedUntil > new Date()
                                || settings.notificationsInhibitedByApplication
    available: true
    active: dnd
    icon: "do_not_disturb_on"
    label: i18n("Focus")
    detail: active ? i18n("Notifications paused") : i18n("Off")
    settingsModule: "kcm_notifications"
    function toggle() {
        if (dnd) {
            settings.notificationsInhibitedUntil = new Date(0)
            settings.revokeApplicationInhibitions()
        } else {
            // until turned off (KDE uses a far-future date for "indefinitely")
            const d = new Date(); d.setFullYear(d.getFullYear() + 1)
            settings.notificationsInhibitedUntil = d
        }
        settings.save()
    }
}
