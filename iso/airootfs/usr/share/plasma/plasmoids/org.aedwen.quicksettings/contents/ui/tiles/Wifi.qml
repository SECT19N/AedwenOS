import QtQuick
import org.kde.plasma.networkmanagement as PlasmaNM
import ".."

Tile {
    PlasmaNM.EnabledConnections { id: conns }
    PlasmaNM.AvailableDevices { id: devices }
    PlasmaNM.NetworkStatus { id: status }
    PlasmaNM.Handler { id: handler }

    available: devices.wirelessDeviceAvailable
    active: conns.wirelessEnabled
    enabled: conns.wirelessHwEnabled && !PlasmaNM.Configuration.airplaneModeEnabled
    icon: active ? "wifi" : "wifi_off"
    label: i18n("Wi‑Fi")
    // activeConnections is "<type>: <status>" per line, e.g.
    // "Wi-Fi: Connected to home-5g"; show the status of the first one.
    readonly property string firstStatus: {
        const line = status.activeConnections.split("\n")[0] || ""
        const i = line.indexOf(": ")
        return i >= 0 ? line.slice(i + 2) : ""
    }
    detail: !active ? i18n("Off")
          : firstStatus ? firstStatus.replace(/^Connected to /, "") : i18n("Not connected")
    settingsModule: "kcm_networkmanagement"
    function toggle() { handler.enableWireless(!conns.wirelessEnabled) }
}
