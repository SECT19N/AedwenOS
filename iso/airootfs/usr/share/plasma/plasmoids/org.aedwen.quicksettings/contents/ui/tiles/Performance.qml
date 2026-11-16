// Power profile: on = "performance"; off = back to balanced. Greyed out when
// power-profiles-daemon isn't running or the hardware has no performance
// profile.
import QtQuick
import org.kde.plasma.private.batterymonitor
import org.aedwen.shell
import ".."

Tile {
    PowerProfilesControl { id: profiles; isSilent: true }
    available: profiles.isPowerProfileDaemonInstalled && profiles.profiles.indexOf("performance") !== -1
    unavailableText: i18n("Not supported")
    active: profiles.activeProfile === "performance"
    icon: profiles.activeProfile === "power-saver" ? "eco" : "bolt"
    label: i18n("Performance")
    hasDetails: true
    // design: the sub-line names the current profile
    detail: profiles.activeProfile === "performance" ? i18n("Performance")
          : profiles.activeProfile === "power-saver" ? i18n("Power saver") : i18n("Balanced")
    settingsModule: "kcm_powerdevilprofilesconfig"
    property var openPage: null
    function configure() { if (openPage) openPage("PowerPage.qml"); else Shell.openSettings(settingsModule) }
    function toggle() { profiles.setProfile(active ? "balanced" : "performance") }
}
