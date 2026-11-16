// Base type for quick-settings tiles: a ToggleTile whose behaviour the
// concrete tile fills in. Override `toggle()`/`configure()` and bind the
// properties to the tile's service.
import QtQuick
import org.aedwen.ui
import org.aedwen.shell

ToggleTile {
    id: tile
    property string settingsModule: ""
    // has a details page in Quick Settings (Internet, Bluetooth,
    // Performance in the design): shows the chevron
    property bool hasDetails: false

    function toggle() {}
    function configure() { if (settingsModule) Shell.openSettings(settingsModule) }

    configurable: settingsModule !== ""
    showChevron: hasDetails
    onToggled: toggle()
    onConfigureRequested: configure()
}
