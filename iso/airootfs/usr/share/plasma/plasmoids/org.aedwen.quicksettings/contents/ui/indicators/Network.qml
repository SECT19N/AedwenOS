// Top-bar network symbol from plasma-nm's connection icon.
import QtQuick
import org.kde.plasma.networkmanagement as PlasmaNM
import org.aedwen.ui

Sym {
    PlasmaNM.ConnectionIcon { id: icon }
    readonly property bool shown: true
    readonly property string kde: icon.connectionIcon
    name: kde.indexOf("airplane") !== -1 ? "airplanemode_active"
        : kde.indexOf("wired") !== -1 ? "lan"
        : kde.indexOf("offline") !== -1 || kde.indexOf("disconnected") !== -1 ? "signal_wifi_off"
        : kde.indexOf("none") !== -1 || kde.indexOf("weak") !== -1 ? "wifi_1_bar"
        : kde.indexOf("low") !== -1 || kde.indexOf("ok") !== -1 ? "wifi_2_bar"
        : kde.indexOf("wireless") !== -1 ? "wifi"
        : kde.indexOf("mobile") !== -1 ? "signal_cellular_alt"
        : "public"
    fill: 1
    size: 18
}
