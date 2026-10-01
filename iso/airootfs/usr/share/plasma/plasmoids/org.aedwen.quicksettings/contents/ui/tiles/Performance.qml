// Power profile: on = "performance"; off = back to balanced. Hidden when
// power-profiles-daemon isn't running or the hardware has no performance
// profile.
import QtQuick
import org.kde.plasma.private.batterymonitor
import ".."

Tile {
    PowerProfilesControl { id: profiles; isSilent: true }
    available: profiles.isPowerProfileDaemonInstalled && profiles.profiles.indexOf("performance") !== -1
    active: profiles.activeProfile === "performance"
    icon: profiles.activeProfile === "power-saver" ? "eco" : "bolt"
    label: i18n("Performance")
    detail: profiles.activeProfile === "performance" ? i18n("On")
          : profiles.activeProfile === "power-saver" ? i18n("Power saver") : i18n("Balanced")
    settingsModule: "kcm_powerdevilprofilesconfig"
    function toggle() { profiles.setProfile(active ? "balanced" : "performance") }
}
