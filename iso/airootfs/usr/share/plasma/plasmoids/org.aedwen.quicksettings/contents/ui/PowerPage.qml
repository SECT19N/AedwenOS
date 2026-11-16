// Power profile details (Desktop design: QUICK SETTINGS detail view),
// opened by holding the Performance tile: the three power-profiles-daemon
// profiles, the active one highlighted with a check.
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.private.batterymonitor
import org.aedwen.ui
import org.aedwen.shell

DetailPage {
    id: page
    PowerProfilesControl { id: profiles; isSilent: true }
    readonly property var defs: [
        ["power-saver", "eco", i18n("Power saver"), i18n("Longer battery, lower clocks")],
        ["balanced", "balance", i18n("Balanced"), i18n("Recommended for most use")],
        ["performance", "bolt", i18n("Performance"), i18n("Max clocks, more fan noise")]
    ].filter(d => profiles.profiles.indexOf(d[0]) !== -1)
    icon: "bolt"
    title: i18n("Power profile")
    section: i18n("Profiles")
    empty: defs.length === 0
    emptyText: i18n("Power profiles aren't available")
    more: i18n("Energy settings")
    onMoreClicked: Shell.openSettings("kcm_powerdevilprofilesconfig")

    Repeater {
        model: page.defs
        DetailRow {
            required property var modelData
            required property int index
            position: index
            count: page.defs.length
            on: profiles.activeProfile === modelData[0]
            icon: modelData[1]
            name: modelData[2]
            sub: modelData[3]
            trail: on ? "check" : ""
            onClicked: profiles.setProfile(modelData[0])
        }
    }
}
