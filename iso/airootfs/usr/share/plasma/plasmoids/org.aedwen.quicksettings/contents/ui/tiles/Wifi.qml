// Network tile (config name "Wifi"). With a wireless card: Wi-Fi on/off and
// the connected network. Without one (wired PCs, VMs): the wired state, and
// the toggle switches networking as a whole. The chevron opens the network
// list inside Quick Settings (NetworkPage.qml) instead of System Settings.
import QtQuick
import org.kde.plasma.networkmanagement as PlasmaNM
import org.aedwen.shell
import ".."

Tile {
    id: tile
    PlasmaNM.EnabledConnections { id: conns }
    PlasmaNM.AvailableDevices { id: devices }
    PlasmaNM.NetworkStatus { id: status }
    PlasmaNM.Handler { id: handler }
    PlasmaNM.ConnectionIcon { id: connIcon }

    // set by QuickSettingsPopup: opens the network page
    property var openPage: null

    readonly property bool wireless: devices.wirelessDeviceAvailable
    available: wireless || devices.wiredDeviceAvailable || devices.modemDeviceAvailable
    unavailableText: i18n("No network device")
    active: wireless ? conns.wirelessEnabled : conns.networkingEnabled && connIcon.connectionIcon.indexOf("offline") === -1
    enabled: !PlasmaNM.Configuration.airplaneModeEnabled && (!wireless || conns.wirelessHwEnabled)
    icon: wireless ? (active ? "wifi" : "wifi_off") : (active ? "lan" : "signal_disconnected")
    label: i18n("Internet")
    hasDetails: true
    // activeConnections is "<type>: <status>" per line, e.g.
    // "Wi-Fi: Connected to home-5g"; show the status of the first one.
    readonly property string firstStatus: {
        const line = status.activeConnections.split("\n")[0] || ""
        const i = line.indexOf(": ")
        return i >= 0 ? line.slice(i + 2) : ""
    }
    detail: wireless && !conns.wirelessEnabled ? i18n("Off")
          : !conns.networkingEnabled ? i18n("Off")
          : firstStatus ? firstStatus.replace(/^Connected to /, "") : i18n("Not connected")
    settingsModule: "kcm_networkmanagement"
    function toggle() {
        if (wireless)
            handler.enableWireless(!conns.wirelessEnabled)
        else
            handler.enableNetworking(!conns.networkingEnabled)
    }
    function configure() {
        if (openPage)
            openPage("NetworkPage.qml")
        else
            Shell.openSettings(settingsModule)
    }
}
