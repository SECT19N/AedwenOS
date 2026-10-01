// Shell-wide actions the widgets trigger, over D-Bus, so any widget (or a
// future app) can open the launcher, search, settings, etc. the same way.
pragma Singleton
import QtQuick
import org.kde.plasma.workspace.dbus as DBus
import org.kde.kcmutils as KCMUtils

QtObject {
    function call(service, path, iface, member, args) {
        return DBus.SessionBus.asyncCall({
            service: service, path: path, iface: iface, member: member,
            arguments: args || []
        })
    }

    // The launcher widget declares X-Plasma-Provides
    // org.kde.plasma.launchermenu, so this is the same as pressing Meta.
    function openLauncher() {
        call("org.kde.plasmashell", "/PlasmaShell", "org.kde.PlasmaShell", "activateLauncherMenu")
    }
    // KRunner (Alt+Space); `query` pre-fills the search.
    function openSearch(query) {
        if (query)
            call("org.kde.krunner", "/App", "org.kde.krunner.App", "query", [new DBus.string(query)])
        else
            call("org.kde.krunner", "/App", "org.kde.krunner.App", "toggleDisplay")
    }
    // A System Settings page by KCM id (e.g. "kcm_networkmanagement"), or
    // the Quick Settings overview page when empty.
    function openSettings(module) {
        KCMUtils.KCMLauncher.openSystemSettings(module || "kcm_landingpage")
    }
    function lockScreen() {
        call("org.freedesktop.ScreenSaver", "/ScreenSaver", "org.freedesktop.ScreenSaver", "Lock")
    }
    // Switch to virtual desktop `n` (1-based).
    function switchDesktop(n) {
        call("org.kde.KWin", "/KWin", "org.kde.KWin", "setCurrentDesktop", [new DBus.int32(n)])
    }
    function showDesktop() {
        call("org.kde.kglobalaccel", "/component/kwin", "org.kde.kglobalaccel.Component",
             "invokeShortcut", [new DBus.string("Show Desktop")])
    }
    function overview() {
        call("org.kde.kglobalaccel", "/component/kwin", "org.kde.kglobalaccel.Component",
             "invokeShortcut", [new DBus.string("Overview")])
    }
}
