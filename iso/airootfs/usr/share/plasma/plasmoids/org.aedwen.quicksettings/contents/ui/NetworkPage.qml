// Network page (opened from the network tile's chevron): every connection
// plasma-nm offers -- wired, Wi-Fi, VPN -- with the active ones first. Click
// connects or disconnects; a secured Wi-Fi network without a saved profile
// asks for its password inline.
import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.plasma.networkmanagement as PlasmaNM
import org.aedwen.ui
import org.aedwen.shell

ColumnLayout {
    id: page
    property var back
    spacing: 8

    PlasmaNM.Handler { id: handler }
    PlasmaNM.EnabledConnections { id: conns }
    PlasmaNM.AvailableDevices { id: devices }
    PlasmaNM.NetworkModel { id: networkModel }
    PlasmaNM.AppletProxyModel { id: networks; sourceModel: networkModel }

    // the row currently asking for a password
    property string passwordFor: ""

    Component.onCompleted: if (devices.wirelessDeviceAvailable) handler.requestScan()

    RowLayout {
        Layout.fillWidth: true
        spacing: 4
        IconButton { icon: "arrow_back"; onClicked: page.back() }
        Label { role: "title"; text: i18n("Network"); Layout.fillWidth: true }
        Switch {
            visible: devices.wirelessDeviceAvailable
            checked: conns.wirelessEnabled
            onToggled: on => handler.enableWireless(on)
        }
    }

    ListView {
        id: list
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        spacing: 2
        model: networks
        boundsBehavior: Flickable.StopAtBounds
        QQC2.ScrollBar.vertical: QQC2.ScrollBar {}

        delegate: Column {
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
            spacing: 4

            function activate() {
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

            ListRow {
                width: parent.width
                title: row.model.ItemUniqueName
                subtitle: row.connected ? i18n("Connected")
                        : row.connecting ? i18n("Connecting…")
                        : row.secured ? i18n("Secured") : ""
                selected: row.connected
                icon: row.model.Type === PlasmaNM.Enums.Wired ? "lan"
                    : row.model.Type === PlasmaNM.Enums.Vpn ? "vpn_key"
                    : !row.wifi ? "public"
                    : row.model.Signal > 75 ? "wifi" : row.model.Signal > 50 ? "network_wifi_3_bar"
                    : row.model.Signal > 25 ? "network_wifi_2_bar" : "network_wifi_1_bar"
                trailing: Sym {
                    visible: row.secured
                    name: "lock"
                    size: 16
                    color: Theme.fgVariant
                }
                onClicked: row.activate()
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

    PillButton {
        Layout.alignment: Qt.AlignRight
        kind: "text"
        compact: true
        text: i18n("Network settings")
        icon: "settings"
        onClicked: Shell.openSettings("kcm_networkmanagement")
    }
}
