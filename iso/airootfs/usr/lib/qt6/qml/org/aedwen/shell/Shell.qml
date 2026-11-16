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
    // The search overlay (aedwen-search, Alt+Space; D-Bus activated if it
    // isn't running); `query` pre-fills it. Falls back to KRunner when the
    // overlay isn't installed.
    function openSearch(query) {
        const reply = query
            ? call("org.aedwen.search", "/Search", "org.aedwen.Search", "query", [new DBus.string(query)])
            : call("org.aedwen.search", "/Search", "org.aedwen.Search", "toggle")
        reply.finished.connect(() => {
            if (!reply.isError)
                return
            if (query)
                call("org.kde.krunner", "/App", "org.kde.krunner.App", "query", [new DBus.string(query)])
            else
                call("org.kde.krunner", "/App", "org.kde.krunner.App", "toggleDisplay")
        })
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
    // New virtual desktop at position `count` (the end); KWin names it.
    function addDesktop(count) {
        call("org.kde.KWin", "/VirtualDesktopManager", "org.kde.KWin.VirtualDesktopManager",
             "createDesktop", [new DBus.uint32(count), new DBus.string("")])
    }
    function removeDesktop(id) {
        call("org.kde.KWin", "/VirtualDesktopManager", "org.kde.KWin.VirtualDesktopManager",
             "removeDesktop", [new DBus.string(id)])
    }
    function showDesktop() {
        call("org.kde.kglobalaccel", "/component/kwin", "org.kde.kglobalaccel.Component",
             "invokeShortcut", [new DBus.string("Show Desktop")])
    }
    function overview() {
        call("org.kde.kglobalaccel", "/component/kwin", "org.kde.kglobalaccel.Component",
             "invokeShortcut", [new DBus.string("AedwenOverview")])
    }
}
