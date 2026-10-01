// Location step ("Where are you?"): region + searchable city list on the
// left, a preview card on the right with the time zone and the language /
// number-format choices. No map, so no QtLocation dependency.
import io.calamares.core 1.0
import io.calamares.ui 1.0
import QtQuick
import QtQuick.Layouts
import "."

Rectangle {
    id: page
    color: Theme.surface

    readonly property var loc: config.currentLocation
    property string region: loc ? loc.region : ""

    function regionIndex() {
        const m = config.regionModel
        for (let i = 0; i < m.rowCount(); ++i)
            if (m.data(m.index(i, 0), Qt.UserRole) === page.region) return i
        return -1
    }
    onRegionChanged: config.regionalZonesModel.region = region
    Component.onCompleted: config.regionalZonesModel.region = region

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 32
        anchors.topMargin: 28
        anchors.bottomMargin: 8
        spacing: 20

        PageHeader {
            Layout.fillWidth: true
            title: qsTr("Where are you?")
            description: qsTr("This sets your time zone, date format and units.")
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 16

            // ---- left: region, search, cities
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: 11
                spacing: 8

                Dropdown {
                    Layout.fillWidth: true
                    icon: "public"
                    model: config.regionModel
                    textRole: "name"
                    currentIndex: page.regionIndex()
                    currentText: page.loc ? config.regionModel.data(config.regionModel.index(currentIndex, 0), Qt.DisplayRole) || "" : ""
                    onActivated: (i) => page.region = config.regionModel.data(config.regionModel.index(i, 0), Qt.UserRole)
                }
                OutlinedField {
                    id: search
                    Layout.fillWidth: true
                    pill: true
                    leadingIcon: "search"
                    placeholder: qsTr("Search for a city")
                }
                ListView {
                    id: zones
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    model: config.regionalZonesModel
                    delegate: Item {
                        readonly property bool match: !search.text
                            || name.toLowerCase().indexOf(search.text.toLowerCase()) >= 0
                        width: zones.width
                        height: match ? 46 : 0
                        visible: match
                        ListRow {
                            anchors.fill: parent
                            anchors.bottomMargin: 2
                            title: name
                            selected: page.loc && page.loc.region === page.region && page.loc.zone === key
                            onClicked: config.setCurrentLocation(page.region, key)
                        }
                    }
                    Component.onCompleted: Qt.callLater(() => {
                        for (let i = 0; i < count; ++i) {
                            const it = itemAtIndex(i)
                            if (it && it.children[0].selected) { positionViewAtIndex(i, ListView.Center); break }
                        }
                    })
                }
            }

            // ---- right: preview card
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredWidth: 10
                Layout.alignment: Qt.AlignTop
                implicitHeight: card.implicitHeight + 36
                radius: Theme.rCard
                color: Theme.scLow

                ColumnLayout {
                    id: card
                    anchors.fill: parent
                    anchors.margins: 18
                    spacing: 14

                    Rectangle {
                        height: 28
                        width: chipText.implicitWidth + 40
                        radius: 14
                        color: Theme.terC
                        Row {
                            anchors.centerIn: parent
                            spacing: 6
                            Sym { name: "schedule"; size: 16; color: Theme.terCFg; anchors.verticalCenter: parent.verticalCenter }
                            Text {
                                id: chipText
                                text: qsTr("Time zone")
                                color: Theme.terCFg
                                font.family: Theme.font
                                font.pixelSize: 12
                                font.weight: Font.DemiBold
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                    }
                    Column {
                        Layout.fillWidth: true
                        spacing: 2
                        Text {
                            width: parent.width
                            text: page.loc ? page.loc.name : ""
                            elide: Text.ElideRight
                            color: Theme.fg
                            font.family: Theme.font
                            font.pixelSize: 40
                            font.weight: Font.Bold
                        }
                        Text {
                            text: config.currentTimezoneCode
                            color: Theme.fgVariant
                            font.family: Theme.font
                            font.pixelSize: 14
                        }
                    }
                    Text {
                        text: qsTr("System language")
                        color: Theme.fgVariant
                        font.family: Theme.font
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                    }
                    Dropdown {
                        Layout.fillWidth: true
                        icon: "language"
                        model: config.supportedLocales
                        currentIndex: config.supportedLocales.indexOf(config.currentLanguageCode)
                        currentText: config.currentLanguageCode
                        onActivated: (i) => config.currentLanguageCode = config.supportedLocales[i]
                    }
                    Text {
                        text: qsTr("Numbers, dates and currency")
                        color: Theme.fgVariant
                        font.family: Theme.font
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                    }
                    Dropdown {
                        Layout.fillWidth: true
                        icon: "schedule"
                        model: config.supportedLocales
                        currentIndex: config.supportedLocales.indexOf(config.currentLCCode)
                        currentText: config.currentLCCode
                        onActivated: (i) => config.currentLCCode = config.supportedLocales[i]
                    }
                }
            }
        }
    }
}
