import QtQuick
import org.kde.bluezqt as BluezQt
import ".."

Tile {
    readonly property var manager: BluezQt.Manager
    readonly property var connected: {
        const out = []
        for (const d of manager.devices) if (d.connected) out.push(d.name)
        return out
    }
    available: manager.operational && manager.adapters.length > 0
    active: manager.bluetoothOperational && !manager.bluetoothBlocked
    icon: active ? (connected.length ? "bluetooth_connected" : "bluetooth") : "bluetooth_disabled"
    label: i18n("Bluetooth")
    detail: !active ? i18n("Off") : connected.length ? connected.join(", ") : i18n("On")
    settingsModule: "kcm_bluetooth"
    function toggle() {
        const block = !manager.bluetoothBlocked
        manager.bluetoothBlocked = block
        for (const a of manager.adapters) a.powered = !block
    }
}
