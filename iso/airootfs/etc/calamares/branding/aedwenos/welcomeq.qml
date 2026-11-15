// Welcome step: eagle in the asymmetric "morph" shape, title, language
// picker, and the requirement checks as chips (design: installer step 0).
import io.calamares.core 1.0
import io.calamares.ui 1.0
import QtQuick
import QtQuick.Layouts
import "."

Rectangle {
    id: page
    color: Theme.surface

    ColumnLayout {
        anchors.centerIn: parent
        width: Math.min(parent.width - 64, 560)
        spacing: 18

        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            width: 104
            height: 104
            color: Theme.pc
            topLeftRadius: 52
            topRightRadius: 52
            bottomRightRadius: 52
            bottomLeftRadius: 29
            EagleMark {
                anchors.centerIn: parent
                width: 60
                height: 60
                tint: "pc-fg"
            }
        }
        Text {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: qsTr("Welcome to %1").arg(Branding.string(Branding.ProductName))
            wrapMode: Text.WordWrap
            color: Theme.fg
            font.family: Theme.font
            font.pixelSize: 38
            font.weight: Font.Bold
        }
        Text {
            Layout.alignment: Qt.AlignHCenter
            Layout.maximumWidth: 440
            horizontalAlignment: Text.AlignHCenter
            text: qsTr("Installing takes about 10 minutes. Nothing on this computer changes until you press Install now.")
            wrapMode: Text.WordWrap
            lineHeight: 1.15
            color: Theme.fgVariant
            font.family: Theme.font
            font.pixelSize: 15
        }
        Dropdown {
            Layout.alignment: Qt.AlignHCenter
            icon: "translate"
            model: config.languagesModel
            textRole: "label"
            currentIndex: config.localeIndex
            currentText: config.languagesModel.data(config.languagesModel.index(config.localeIndex, 0), Qt.DisplayRole) || ""
            onActivated: (i) => config.localeIndex = i
        }

        // Requirement checks: a chip per check (design: installer step 0,
        // "At least 20 GB free" / "Plugged in" / ...). Met checks get a short
        // label of our own -- Calamares' `details` is a fragment meant to
        // follow "This computer ..." ("has at least 2 GiB working memory"),
        // and for storage it is two sentences. Unmet ones show Calamares'
        // full reason and turn red (mandatory) or tertiary (recommended).
        // The chips wrap onto more lines and stay centred.
        Flow {
            id: chips
            readonly property int maxChip: 360
            // Flow can't centre its rows, so size it to its content: the
            // widest line the chips fill, capped at the page width.
            property real contentWidth: 0
            function relayout() {
                let w = 0
                for (let i = 0; i < chipRepeater.count; i++) {
                    const it = chipRepeater.itemAt(i)
                    if (it) w += it.width + (i > 0 ? spacing : 0)
                }
                contentWidth = w
            }
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: Math.min(contentWidth, parent.width)
            Layout.topMargin: 6
            spacing: 8

            function label(name, details) {
                const n = (String(details).match(/\d+(?:\.\d+)?/) || [""])[0]
                switch (name) {
                case "storage": return qsTr("At least %1 GB free").arg(n)
                case "ram": return qsTr("At least %1 GB of memory").arg(n)
                case "power": return qsTr("Plugged in")
                case "internet": return qsTr("Connected to the internet")
                case "root": return qsTr("Running as administrator")
                case "screen": return qsTr("Screen is large enough")
                }
                // anything else: Calamares' text, first sentence, no markup
                return String(details).replace(/<[^>]*>/g, " ").split(/\.\s/)[0].trim()
            }

            Repeater {
                id: chipRepeater
                model: config.requirementsModel
                onItemAdded: chips.relayout()
                onItemRemoved: chips.relayout()

                Rectangle {
                    width: chipContent.implicitWidth + 12 + 8
                    height: Math.max(32, chipText.implicitHeight + 12)
                    radius: 8
                    color: satisfied ? "transparent" : (mandatory ? Theme.errC : Theme.terC)
                    border.width: satisfied ? 1 : 0
                    border.color: Theme.outlineV
                    onWidthChanged: chips.relayout()

                    Row {
                        id: chipContent
                        x: 8
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 6
                        Sym {
                            size: 18
                            fill: 1
                            name: satisfied ? "check_circle" : (mandatory ? "error" : "warning")
                            color: satisfied ? Theme.primary : (mandatory ? Theme.errCFg : Theme.terCFg)
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            id: chipText
                            width: Math.min(implicitWidth, chips.maxChip - 44)
                            text: satisfied ? chips.label(model.name, details) : negatedText
                            textFormat: Text.PlainText
                            wrapMode: Text.WordWrap
                            color: satisfied ? Theme.fg : (mandatory ? Theme.errCFg : Theme.terCFg)
                            font.family: Theme.font
                            font.pixelSize: 13
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }
            }
        }
        Text {
            Layout.fillWidth: true
            visible: !config.requirementsModel.satisfiedMandatory
            horizontalAlignment: Text.AlignHCenter
            text: qsTr("This computer doesn't meet the minimum requirements for %1, so installation can't continue.").arg(Branding.string(Branding.ProductName))
            wrapMode: Text.WordWrap
            color: Theme.err
            font.family: Theme.font
            font.pixelSize: 13
        }
    }
}
