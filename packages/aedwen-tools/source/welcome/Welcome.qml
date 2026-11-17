// The first-run Welcome app (System Surfaces design, section 07): a
// header (eagle tile, "Welcome, <name>", a line of help), a 2-column grid of
// cards (a primary-container "Pick a colour" card whose dots recolour the
// whole desktop live, then three links), and a footer with "Show on
// startup" and Done. The window frame and its close button come from the
// AedwenOS window decoration.
import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import org.aedwen.ui

Window {
    id: win
    visible: true
    title: i18n("Welcome to AedwenOS")
    width: 640
    height: 468
    minimumWidth: 560
    minimumHeight: 440
    color: Theme.surface

    onClosing: controller.finish()

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 26
        spacing: 18

        RowLayout {
            Layout.fillWidth: true
            spacing: 16
            Rectangle {
                Layout.preferredWidth: 52
                Layout.preferredHeight: 52
                radius: 16
                color: Theme.primary
                EagleMark {
                    anchors.centerIn: parent
                    width: 30
                    height: 30
                    color: Theme.primaryFg
                }
            }
            ColumnLayout {
                spacing: 2
                Label {
                    text: i18n("Welcome, %1", controller.userName)
                    font.pixelSize: 26
                    font.weight: Font.DemiBold
                }
                Label {
                    text: i18n("A few things to make it yours.")
                    font.pixelSize: 14
                    color: Theme.fgVariant
                }
            }
        }

        GridLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            columns: 2
            rowSpacing: 8
            columnSpacing: 8

            // pick a colour: spans both columns
            Rectangle {
                Layout.columnSpan: 2
                Layout.fillWidth: true
                Layout.preferredHeight: 92
                radius: Theme.rCard
                color: Theme.pc
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 14
                    Sym { name: "palette"; fill: 1; size: 26; color: Theme.pcFg }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Label { text: i18n("Pick a colour"); font.pixelSize: 14; font.weight: Font.DemiBold; color: Theme.pcFg }
                        Label {
                            text: i18n("Everything follows it: apps, icons, cursors and the boot screen")
                            font.pixelSize: 13
                            color: Theme.pcFg
                            opacity: 0.8
                            Layout.fillWidth: true
                            wrapMode: Text.Wrap
                        }
                    }
                    Row {
                        spacing: 8
                        Repeater {
                            model: controller.seeds
                            Rectangle {
                                id: dot
                                required property var modelData
                                readonly property bool on: controller.seed === modelData.name
                                width: 22
                                height: 22
                                radius: 11
                                color: modelData.hex
                                border.width: on ? 2 : 0
                                border.color: Theme.pcFg
                                // the ring sits outside the dot, as in the design
                                Rectangle {
                                    anchors.centerIn: parent
                                    width: 30
                                    height: 30
                                    radius: 15
                                    color: "transparent"
                                    border.width: 2
                                    border.color: Theme.pcFg
                                    visible: dot.on
                                }
                                scale: dotMouse.containsMouse ? 1.12 : 1
                                Behavior on scale { NumberAnimation { duration: Theme.durShort } }
                                MouseArea {
                                    id: dotMouse
                                    anchors.fill: parent
                                    anchors.margins: -4
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: controller.setSeed(dot.modelData.name)
                                }
                                Accessible.role: Accessible.RadioButton
                                Accessible.name: modelData.name
                                Accessible.checked: on
                            }
                        }
                    }
                }
            }

            Repeater {
                model: [
                    { icon: "dock_to_bottom", title: i18n("Choose a layout"), text: i18n("Dock with a top bar, or a single panel"),
                      run: ["kcmshell6", ["kcm_aedwen_appearance"]] },
                    { icon: "storefront", title: i18n("Get apps"), text: i18n("Browse and install packages"),
                      run: ["octopi", []] },
                    { icon: "keyboard", title: i18n("Learn shortcuts"), text: i18n("Overview, tiling and search in 2 minutes"),
                      run: ["kcmshell6", ["kcm_keys"]] }
                ]
                Rectangle {
                    id: card
                    required property var modelData
                    required property int index
                    // the last card takes the whole row, so the grid has no hole
                    Layout.columnSpan: index === 2 ? 2 : 1
                    Layout.fillWidth: true
                    Layout.preferredHeight: 76
                    radius: Theme.rCard
                    color: Theme.scLow
                    StateLayer { area: cardMouse }
                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 14
                        Sym { name: card.modelData.icon; fill: 1; size: 24; color: Theme.primary }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1
                            Label { text: card.modelData.title; font.pixelSize: 14; font.weight: Font.DemiBold }
                            Label {
                                text: card.modelData.text
                                font.pixelSize: 13
                                color: Theme.fgVariant
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }
                        }
                    }
                    MouseArea {
                        id: cardMouse
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: controller.launch(card.modelData.run[0], card.modelData.run[1])
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 10
            Switch {
                checked: controller.showOnStartup
                onToggled: c => controller.showOnStartup = c
            }
            Label { text: i18n("Show on startup"); font.pixelSize: 13; color: Theme.fgVariant }
            Item { Layout.fillWidth: true }
            PillButton {
                text: i18n("Done")
                onClicked: {
                    controller.finish()
                    Qt.quit()
                }
            }
        }
    }
}
