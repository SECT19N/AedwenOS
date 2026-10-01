// Base type for quick-settings tiles: a ToggleTile whose behaviour the
// concrete tile fills in. Override `toggle()`/`configure()` and bind the
// properties to the tile's service.
import QtQuick
import org.aedwen.ui
import org.aedwen.shell

ToggleTile {
    id: tile
    property bool available: true
    property string settingsModule: ""

    function toggle() {}
    function configure() { if (settingsModule) Shell.openSettings(settingsModule) }

    configurable: settingsModule !== ""
    onToggled: toggle()
    onConfigureRequested: configure()
}
