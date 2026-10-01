// Night light: on = KWin night light is enabled and running. Toggling
// suspends/resumes it (like KDE's brightness applet); if it is turned off
// entirely in settings, the tile opens those settings instead.
import QtQuick
import org.kde.plasma.workspace.dbus as DBus
import org.kde.plasma.private.brightnesscontrolplugin
import ".."

Tile {
    DBus.Properties {
        id: kwin
        busType: DBus.BusType.Session
        service: "org.kde.KWin.NightLight"
        path: "/org/kde/KWin/NightLight"
        iface: "org.kde.KWin.NightLight"
    }

    available: Boolean(kwin.properties.available)
    active: Boolean(kwin.properties.enabled) && Boolean(kwin.properties.running)
    icon: "nightlight"
    label: i18n("Night light")
    detail: !kwin.properties.enabled ? i18n("Off") : active ? i18n("On") : i18n("Paused")
    settingsModule: "kcm_nightlight"
    function toggle() {
        if (!kwin.properties.enabled) configure()
        else NightLightInhibitor.toggleInhibition()
    }
}
