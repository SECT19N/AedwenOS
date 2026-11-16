import QtQuick
import org.kde.bluezqt as BluezQt
import org.aedwen.shell
import ".."

Tile {
    readonly property var manager: BluezQt.Manager
    readonly property var connected: {
        const out = []
        for (const d of manager.devices) if (d.connected) out.push(d.name)
        return out
    }
    available: manager.operational && manager.adapters.length > 0
    unavailableText: i18n("No adapter")
    active: manager.bluetoothOperational && !manager.bluetoothBlocked
    icon: active ? (connected.length ? "bluetooth_connected" : "bluetooth") : "bluetooth_disabled"
    label: i18n("Bluetooth")
    hasDetails: true
    detail: !active ? i18n("Off") : connected.length ? i18np("%1 device", "%1 devices", connected.length) : i18n("On")
    settingsModule: "kcm_bluetooth"
    // set by QuickSettingsPopup: opens a details page
    property var openPage: null
    function configure() { if (openPage) openPage("BluetoothPage.qml"); else Shell.openSettings(settingsModule) }
    function toggle() {
        const block = !manager.bluetoothBlocked
        manager.bluetoothBlocked = block
        for (const a of manager.adapters) a.powered = !block
    }
}
