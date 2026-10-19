// Removable drives (USB sticks, SD cards, phones in storage mode), in place
// of KDE's separate Disks & Devices tray popup. Shown only while one is
// plugged in. Click mounts if needed and opens it in the file manager; the
// eject button unmounts.
//
// Data: the "hotplug" engine lists hotplugged devices by UDI, "soliddevice"
// gives each one's mount state, path and free space and does the
// mount/unmount (Plasma5Support, both shipped by plasma-workspace).
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasma5support as P5Support
import org.aedwen.ui

ColumnLayout {
    id: drives
    // removable volumes, minus the running system's own mounts (hot-swap
    // SATA disks report Removable too)
    readonly property var systemMounts: ["/", "/boot", "/boot/efi", "/efi", "/home"]
    readonly property var udis: hotplug.sources.filter(udi => {
        const d = solid.data[udi]
        return d && d["Removable"] && systemMounts.indexOf(d["File Path"]) === -1
    })
    readonly property bool available: udis.length > 0
    spacing: 2

    P5Support.DataSource {
        id: hotplug
        engine: "hotplug"
        connectedSources: sources
    }
    P5Support.DataSource {
        id: solid
        engine: "soliddevice"
        connectedSources: hotplug.sources
        interval: 10000      // refresh free space
    }

    function operation(udi, name) {
        const service = solid.serviceForSource(udi)
        service.startOperationCall(service.operationDescription(name))
    }
    Label {
        role: "label"
        text: i18n("Drives")
        color: Theme.fgVariant
        Layout.leftMargin: 4
        Layout.bottomMargin: 4
    }

    Repeater {
        model: drives.udis
        ListRow {
            id: row
            required property string modelData
            readonly property var dev: solid.data[modelData] || ({})
            readonly property var hp: hotplug.data[modelData] || ({})
            readonly property bool mounted: Boolean(dev["Accessible"])
            // open once mounted, when the click asked for it
            property bool openWhenMounted: false

            Layout.fillWidth: true
            title: dev["Label"] || hp["text"] || dev["Product"] || i18n("Drive")
            subtitle: mounted && dev["Free Space Text"]
                      ? i18n("%1 free of %2", dev["Free Space Text"], dev["Size Text"])
                      : dev["Size Text"] || ""
            readonly property string kdeIcon: String(dev["Icon"] || "")
            icon: kdeIcon.indexOf("phone") !== -1 ? "smartphone"
                : kdeIcon.indexOf("flash") !== -1 || kdeIcon.indexOf("sd-") !== -1 ? "sd_card"
                : kdeIcon.indexOf("optical") !== -1 ? "album"
                : "usb"
            trailing: IconButton {
                visible: row.mounted
                icon: "eject"
                size: 32
                iconSize: 18
                tooltip: i18n("Safely remove")
                onClicked: drives.operation(row.modelData, "unmount")
            }
            onClicked: {
                if (mounted) {
                    Qt.openUrlExternally("file://" + dev["File Path"])
                } else {
                    openWhenMounted = true
                    drives.operation(modelData, "mount")
                }
            }
            onMountedChanged: if (mounted && openWhenMounted) {
                openWhenMounted = false
                Qt.openUrlExternally("file://" + dev["File Path"])
            }
        }
    }
}
