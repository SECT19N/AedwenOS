// Extras step ("Pick what you want"): optional software packs. They are all
// on the live system; the installer removes the ones left off (see the
// shellprocess-postinstall module and /etc/calamares/packs, which lists
// each pack's packages). Nothing is on by default.
import io.calamares.core 1.0
import io.calamares.ui 1.0
import QtQuick
import QtQuick.Layouts
import "."

Rectangle {
    id: page
    color: Theme.surface

    // ids match /etc/calamares/packs
    readonly property var packs: [
        { id: "dev", title: qsTr("Developer tools"),
          text: qsTr("Compilers and build tools, Git, GitHub CLI, Node.js, uv, debuggers, tmux") },
        { id: "print", title: qsTr("Printing"),
          text: qsTr("CUPS and the printer settings, for connecting to a printer") },
        { id: "bluetooth", title: qsTr("Bluetooth"),
          text: qsTr("Bluetooth support and its settings, for wireless devices") },
        { id: "extras", title: qsTr("More KDE apps"),
          text: qsTr("Okular (documents), Filelight (disk usage), System Info, Partition Manager and Calculator") }
    ]
    property var selected: ({})

    function publish() {
        Global.insert("aedwenPacks", packs.filter(p => selected[p.id]).map(p => p.id).join(","))
    }
    Component.onCompleted: publish()   // nothing selected until the user asks

    Flickable {
        anchors.fill: parent
        contentHeight: content.implicitHeight + 36
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: content
            x: 32
            y: 28
            width: parent.width - 64
            spacing: 20

            PageHeader {
                Layout.fillWidth: true
                title: qsTr("Pick what you want")
                description: qsTr("AedwenOS installs light. Turn on the extras you’ll use; you can add them later from the Store.")
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                Repeater {
                    model: page.packs
                    SwitchRow {
                        Layout.fillWidth: true
                        topLeftRadius: index === 0 ? Theme.rCard : 0
                        topRightRadius: index === 0 ? Theme.rCard : 0
                        bottomLeftRadius: index === page.packs.length - 1 ? Theme.rCard : 0
                        bottomRightRadius: index === page.packs.length - 1 ? Theme.rCard : 0
                        title: modelData.title
                        description: modelData.text
                        checked: !!page.selected[modelData.id]
                        onToggled: (c) => {
                            const s = Object.assign({}, page.selected)
                            s[modelData.id] = c
                            page.selected = s
                            page.publish()
                        }
                    }
                }
            }
        }
    }
}
