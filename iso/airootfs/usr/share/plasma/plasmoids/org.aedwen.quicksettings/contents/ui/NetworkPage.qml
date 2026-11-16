// Internet details (Desktop design: QUICK SETTINGS detail view), opened by
// holding the Internet tile: every connection plasma-nm offers -- wired,
// Wi-Fi, VPN -- with the active ones first. Click connects or disconnects;
// a secured Wi-Fi network without a saved profile asks for its password
// inline.
import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.plasma.networkmanagement as PlasmaNM
import org.aedwen.ui
import org.aedwen.shell

DetailPage {
    id: page
    icon: "wifi"
    title: i18n("Internet")
    hasSwitch: devices.wirelessDeviceAvailable
    switchOn: conns.wirelessEnabled
    onSwitchToggled: on => handler.enableWireless(on)
    section: devices.wirelessDeviceAvailable ? i18n("Wi‑Fi networks") : i18n("Connections")
    empty: devices.wirelessDeviceAvailable && !conns.wirelessEnabled && list.count === 0
    emptyText: i18n("Wi‑Fi is off")
    more: i18n("Network settings")
    onMoreClicked: Shell.openSettings("kcm_networkmanagement")

    PlasmaNM.Handler { id: handler }
    PlasmaNM.EnabledConnections { id: conns }
    PlasmaNM.AvailableDevices { id: devices }
    PlasmaNM.NetworkModel { id: networkModel }
    PlasmaNM.AppletProxyModel { id: networks; sourceModel: networkModel }

    // the row currently asking for a password
    property string passwordFor: ""

    Component.onCompleted: if (devices.wirelessDeviceAvailable) handler.requestScan()

    ListView {
        id: list
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(contentHeight, 380)
        clip: true
        spacing: page.rowSpacing
        model: networks
        boundsBehavior: Flickable.StopAtBounds
        QQC2.ScrollBar.vertical: QQC2.ScrollBar {}

        delegate: DetailRow {
            id: row
            required property var model
            required property int index
            readonly property bool connected: model.ConnectionState === PlasmaNM.Enums.Activated
            readonly property bool connecting: model.ConnectionState === PlasmaNM.Enums.Activating
            readonly property bool wifi: model.Type === PlasmaNM.Enums.Wireless
            readonly property bool secured: wifi && model.SecurityType > PlasmaNM.Enums.NoneSecurity
            readonly property bool needsPassword: wifi && !model.Uuid
                && (model.SecurityType === PlasmaNM.Enums.StaticWep
                    || model.SecurityType === PlasmaNM.Enums.WpaPsk
                    || model.SecurityType === PlasmaNM.Enums.SAE)
            width: list.width
            position: index
            count: list.count
            on: connected
            name: model.ItemUniqueName
            sub: connected ? i18n("Connected")
               : connecting ? i18n("Connecting…")
               : secured ? i18n("Secured") : wifi ? i18n("Open network") : ""
            icon: model.Type === PlasmaNM.Enums.Wired ? "lan"
                : model.Type === PlasmaNM.Enums.Vpn ? "vpn_key"
                : !wifi ? "public"
                : model.Signal > 75 ? "wifi" : model.Signal > 50 ? "network_wifi_3_bar"
                : model.Signal > 25 ? "network_wifi_2_bar" : "network_wifi_1_bar"
            trail: connected ? "settings" : secured ? "lock" : ""
            onTrailClicked: if (connected) Shell.openSettings("kcm_networkmanagement")

            onClicked: {
                if (connected || connecting) {
                    handler.deactivateConnection(model.ConnectionPath, model.DevicePath)
                } else if (needsPassword) {
                    page.passwordFor = page.passwordFor === model.ItemUniqueName ? "" : model.ItemUniqueName
                } else if (!model.Uuid) {
                    handler.addAndActivateConnection(model.DevicePath, model.SpecificPath)
                } else {
                    handler.activateConnection(model.ConnectionPath, model.DevicePath, model.SpecificPath)
                }
            }

            RowLayout {
                visible: page.passwordFor === row.model.ItemUniqueName
                width: parent.width
                spacing: 8
                QQC2.TextField {
                    id: password
                    Layout.fillWidth: true
                    echoMode: TextInput.Password
                    placeholderText: i18n("Password")
                    onVisibleChanged: if (visible) { text = ""; forceActiveFocus() }
                    onAccepted: connect.clicked()
                }
                PillButton {
                    id: connect
                    kind: "filled"
                    compact: true
                    text: i18n("Connect")
                    enabled: password.text.length >= 8 || row.model.SecurityType === PlasmaNM.Enums.StaticWep
                    onClicked: {
                        handler.addAndActivateConnection(row.model.DevicePath, row.model.SpecificPath, password.text)
                        page.passwordFor = ""
                    }
                }
            }
        }
    }
}
