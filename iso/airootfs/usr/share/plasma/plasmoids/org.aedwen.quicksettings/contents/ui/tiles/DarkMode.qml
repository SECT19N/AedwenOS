// Dark mode: switches between the light and dark AedwenOS global themes
// (kdeglobals DefaultLightLookAndFeel / DefaultDarkLookAndFeel), through
// the same control KDE's brightness applet uses.
import QtQuick
import org.kde.plasma.private.brightnesscontrolplugin
import ".."

Tile {
    available: true
    active: DarkModeControl.darkMode
    icon: "dark_mode"
    label: i18n("Dark mode")
    detail: active ? i18n("On") : i18n("Off")
    settingsModule: "kcm_lookandfeel"
    function toggle() { DarkModeControl.darkMode = !DarkModeControl.darkMode }
}
