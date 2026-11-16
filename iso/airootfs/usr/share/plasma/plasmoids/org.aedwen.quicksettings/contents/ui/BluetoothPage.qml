// Bluetooth details (Desktop design: QUICK SETTINGS detail view), opened by
// holding the Bluetooth tile: paired devices, connected ones highlighted.
// Click (or the link symbol) connects / disconnects.
import QtQuick
import QtQuick.Layouts
import org.kde.bluezqt as BluezQt
import org.aedwen.ui
import org.aedwen.shell

DetailPage {
    id: page
    readonly property var manager: BluezQt.Manager
    readonly property bool on: manager.bluetoothOperational && !manager.bluetoothBlocked
    readonly property var paired: {
        const out = []
        for (const d of manager.devices) if (d.paired) out.push(d)
        out.sort((a, b) => (b.connected - a.connected) || a.name.localeCompare(b.name))
        return out
    }
    icon: "bluetooth"
    title: i18n("Bluetooth")
    hasSwitch: true
    switchOn: on
    onSwitchToggled: checked => {
        manager.bluetoothBlocked = !checked
        for (const a of manager.adapters) a.powered = checked
    }
    section: i18n("Devices")
    empty: !on || paired.length === 0
    emptyText: on ? i18n("No paired devices") : i18n("Bluetooth is off")
    more: i18n("Pair new device")
    onMoreClicked: Shell.openSettings("kcm_bluetooth")

    // BluezQt::Device::Type values (the enum lives on the C++ base class,
    // which the QML Device type doesn't re-export): Phone 0, Computer 2,
    // Headset 4, Headphones 5, AudioVideo 6, Keyboard 7, Mouse 8, Joypad 9
    function symbolFor(d) {
        switch (d.type) {
        case 4: case 5: case 6: return "headphones"
        case 8: return "mouse"
        case 7: return "keyboard"
        case 0: return "smartphone"
        case 2: return "computer"
        case 9: return "sports_esports"
        default: return "bluetooth"
        }
    }

    Repeater {
        model: page.paired
        DetailRow {
            required property var modelData
            required property int index
            position: index
            count: page.paired.length
            on: modelData.connected
            icon: page.symbolFor(modelData)
            name: modelData.name
            sub: modelData.connected
                 ? (modelData.battery ? i18n("Connected · battery %1%", modelData.battery.percentage) : i18n("Connected"))
                 : i18n("Paired")
            trail: modelData.connected ? "link_off" : "link"
            function flip() { if (modelData.connected) modelData.disconnectFromDevice(); else modelData.connectToDevice() }
            onClicked: flip()
            onTrailClicked: flip()
        }
    }
}
