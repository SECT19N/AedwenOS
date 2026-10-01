// Summary step ("Ready to install"): an error-container warning, then one
// row per earlier step with what it will do and a "Change" button that
// goes back to that step.
import io.calamares.core 1.0
import io.calamares.ui 1.0
import QtQuick
import QtQuick.Layouts
import "."

Rectangle {
    id: page
    color: Theme.surface

    readonly property var icons: ({ "Location": "location_on", "Keyboard": "keyboard",
                                    "Partitions": "hard_drive", "Users": "person" })
    readonly property var names: ({ "Partitions": qsTr("Disk") })

    // ViewManager has no "go to step", so step back until we get there.
    function goTo(title) {
        for (let i = 0; i < ViewManager.rowCount(); ++i) {
            if (ViewManager.data(ViewManager.index(i, 0), Qt.DisplayRole) === title) {
                for (let n = ViewManager.currentStepIndex - i; n > 0; --n) ViewManager.back()
                return
            }
        }
    }

    Flickable {
        id: flick
        anchors.fill: parent
        contentHeight: content.implicitHeight + 36
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: content
            x: 32
            y: 28
            width: flick.width - 64
            spacing: 20

            PageHeader {
                Layout.fillWidth: true
                title: qsTr("Ready to install")
                description: qsTr("Check everything once more. You can still go back and change anything.")
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: warn.implicitHeight + 28
                radius: Theme.rCard
                color: Theme.errC
                RowLayout {
                    id: warn
                    anchors.fill: parent
                    anchors.margins: 14
                    anchors.leftMargin: 16
                    spacing: 14
                    Sym { name: "warning"; fill: 1; size: 24; color: Theme.errCFg }
                    Text {
                        Layout.fillWidth: true
                        text: qsTr("<b>The disk changes below happen as soon as you press Install now.</b> They can’t be undone.")
                        textFormat: Text.StyledText
                        wrapMode: Text.WordWrap
                        color: Theme.errCFg
                        font.family: Theme.font
                        font.pixelSize: 14
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                Repeater {
                    id: rows
                    model: config.summaryModel
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: Math.max(58, body.implicitHeight + 20)
                        color: Theme.scLow
                        topLeftRadius: index === 0 ? Theme.rCard : 0
                        topRightRadius: index === 0 ? Theme.rCard : 0
                        bottomLeftRadius: index === rows.count - 1 ? Theme.rCard : 0
                        bottomRightRadius: index === rows.count - 1 ? Theme.rCard : 0

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 16
                            anchors.rightMargin: 8
                            spacing: 14
                            Sym {
                                Layout.alignment: Qt.AlignTop
                                Layout.topMargin: 12
                                name: page.icons[model.title] || "info"
                                size: 22
                                color: Theme.fgVariant
                            }
                            Column {
                                id: body
                                Layout.fillWidth: true
                                spacing: 2
                                Text {
                                    width: parent.width
                                    text: page.names[model.title] || model.title
                                    color: Theme.fgVariant
                                    font.family: Theme.font
                                    font.pixelSize: 12
                                }
                                Text {
                                    width: parent.width
                                    text: model.message
                                    textFormat: Text.RichText
                                    wrapMode: Text.WordWrap
                                    color: Theme.fg
                                    linkColor: Theme.primary
                                    font.family: Theme.font
                                    font.pixelSize: 14
                                }
                            }
                            PillButton {
                                Layout.alignment: Qt.AlignTop
                                Layout.topMargin: 10
                                kind: "text"
                                compact: true
                                text: qsTr("Change")
                                onClicked: page.goTo(model.title)
                            }
                        }
                    }
                }
            }
        }
    }
}
