// Extras step ("Pick what you want"): optional software, one switch per item.
// Ids match /usr/share/aedwen/extras, which says what each one installs:
//   (on the image)  removed again after the copy when left off
//   (download)      fetched from the repositories at the end of the install
//                   when ticked (needs a network; `aedwen-extras` can do it
//                   later). Nothing is on by default.
// The ticked ids go to global storage as `aedwenPacks` ("python,zed"), which
// shellprocess-postinstall hands to aedwen-extras-apply.sh.
import io.calamares.core 1.0
import io.calamares.ui 1.0
import QtQuick
import QtQuick.Layouts
import "."

Rectangle {
    id: page
    color: Theme.surface

    // download: true -> not on the image, fetched during the install
    readonly property var groups: [
        { title: qsTr("Developer tools"), items: [
            { id: "dev-core", title: qsTr("Build tools and Git"),
              text: qsTr("Compilers and build tools, Git, GitHub CLI, debugger, ripgrep, fd and tmux") },
            { id: "python", title: qsTr("Python"), download: true,
              text: qsTr("uv, pip, pipx and the Pyright language server (about 6 MB download)") },
            { id: "javascript", title: qsTr("JavaScript and TypeScript"), download: true,
              text: qsTr("Node.js, npm, pnpm, TypeScript and its language server (about 20 MB download)") }
        ] },
        { title: qsTr("Editors"), items: [
            { id: "zed", title: qsTr("Zed"), download: true,
              text: qsTr("A fast native code editor (about 82 MB download)") },
            { id: "neovim", title: qsTr("Neovim"), download: true,
              text: qsTr("The terminal editor (about 7 MB download)") },
            { id: "helix", title: qsTr("Helix"), download: true,
              text: qsTr("A modal terminal editor with built-in language support (about 18 MB download)") },
            { id: "vscode", title: qsTr("Visual Studio Code (Code - OSS)"), download: true,
              text: qsTr("The open-source build of VS Code. It is an Electron app, so it brings its own browser engine (about 130 MB download)") }
        ] },
        { title: qsTr("KDE apps"), items: [
            { id: "okular", title: qsTr("Okular"), text: qsTr("Documents and PDFs") },
            { id: "filelight", title: qsTr("Filelight"), text: qsTr("See what is using your disk space") },
            { id: "kinfocenter", title: qsTr("System Info"), text: qsTr("Hardware and system information") },
            { id: "partitionmanager", title: qsTr("Partition Manager"), text: qsTr("Create and resize partitions") },
            { id: "kcalc", title: qsTr("Calculator"), text: qsTr("A scientific calculator") },
            { id: "kfind", title: qsTr("KFind"), text: qsTr("Search for files by name and content") },
            { id: "elisa", title: qsTr("Elisa"), download: true,
              text: qsTr("Music player (about 2 MB download)") },
            { id: "haruna", title: qsTr("Haruna"), download: true,
              text: qsTr("Video player (about 2 MB download)") },
            { id: "kdenlive", title: qsTr("Kdenlive"), download: true,
              text: qsTr("Video editor (about 22 MB download)") },
            { id: "krita", title: qsTr("Krita"), download: true,
              text: qsTr("Painting and illustration (about 70 MB download)") },
            { id: "kolourpaint", title: qsTr("KolourPaint"), download: true,
              text: qsTr("Simple image editor (about 5 MB download)") },
            { id: "kdeconnect", title: qsTr("KDE Connect"), download: true,
              text: qsTr("Link your phone: notifications, files, clipboard (about 2 MB download)") }
        ] },
        { title: qsTr("Hardware"), items: [
            { id: "print", title: qsTr("Printing"),
              text: qsTr("CUPS and the printer settings, for connecting to a printer") },
            { id: "bluetooth", title: qsTr("Bluetooth"),
              text: qsTr("Bluetooth support and its settings, for wireless devices") }
        ] }
    ]
    property var selected: ({})
    readonly property bool anyDownload: {
        for (const g of groups)
            for (const it of g.items)
                if (it.download && selected[it.id])
                    return true
        return false
    }

    function publish() {
        const ids = []
        for (const g of groups)
            for (const it of g.items)
                if (selected[it.id])
                    ids.push(it.id)
        Global.insert("aedwenPacks", ids.join(","))
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
                description: qsTr("AedwenOS installs light. Turn on the extras you’ll use; you can add them later with aedwen-extras or from the Store.")
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: note.implicitHeight + 24
                radius: Theme.rInner
                color: page.anyDownload ? Theme.secC : Theme.scLow
                Text {
                    id: note
                    anchors.fill: parent
                    anchors.margins: 12
                    wrapMode: Text.WordWrap
                    verticalAlignment: Text.AlignVCenter
                    color: page.anyDownload ? Theme.secCFg : Theme.fgVariant
                    font.family: Theme.font
                    font.pixelSize: 13
                    text: page.anyDownload
                        ? qsTr("Items marked “download” are fetched at the end of the install and need a network connection. If the install is offline they are skipped; run “aedwen-extras pending” once you are online.")
                        : qsTr("Items marked “download” are not on the install image; they are fetched at the end of the install and need a network connection.")
                }
            }

            Repeater {
                model: page.groups
                ColumnLayout {
                    id: section
                    required property var modelData
                    Layout.fillWidth: true
                    spacing: 8

                    Text {
                        Layout.leftMargin: 4
                        text: section.modelData.title
                        color: Theme.primary
                        font.family: Theme.font
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Repeater {
                            model: section.modelData.items
                            SwitchRow {
                                required property var modelData
                                required property int index
                                readonly property int last: section.modelData.items.length - 1
                                Layout.fillWidth: true
                                topLeftRadius: index === 0 ? Theme.rCard : 0
                                topRightRadius: index === 0 ? Theme.rCard : 0
                                bottomLeftRadius: index === last ? Theme.rCard : 0
                                bottomRightRadius: index === last ? Theme.rCard : 0
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
    }
}
