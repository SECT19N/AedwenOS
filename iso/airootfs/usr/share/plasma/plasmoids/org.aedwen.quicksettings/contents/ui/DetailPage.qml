// A Quick Settings details page (Desktop design: QUICK SETTINGS, detail
// view): a 40 px round back button, the tile's symbol in primary, a title
// and an optional switch; a primary section label; the rows (DetailRow,
// grouped: 2 px apart, inner corners 4 px in Expressive); an empty-state
// line; and a pill text link at the bottom ("Network settings" ...).
import QtQuick
import QtQuick.Layouts
import org.aedwen.ui

ColumnLayout {
    id: page
    property var back
    property string icon
    property string title
    property bool hasSwitch: false
    property bool switchOn: false
    property string section
    property bool empty: false
    property string emptyText
    property string more
    // rows go here; they lay out in a column `rowSpacing` apart
    default property alias rows: list.data
    readonly property int rowSpacing: Theme.expressive ? 2 : 8
    signal switchToggled(bool on)
    signal moreClicked()

    spacing: 16

    RowLayout {
        Layout.fillWidth: true
        spacing: 8
        Rectangle {
            implicitWidth: 40
            implicitHeight: 40
            radius: 20
            color: backMouse.containsMouse ? Theme.secC : Theme.scHighest
            Behavior on color { ColorAnimation { duration: Theme.durShort } }
            Sym { anchors.centerIn: parent; name: "arrow_back"; size: 22 }
            MouseArea {
                id: backMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: page.back()
            }
        }
        Sym {
            Layout.leftMargin: 6
            name: page.icon
            size: 22
            fill: 1
            color: Theme.primary
        }
        Label {
            Layout.fillWidth: true
            text: page.title
            font.pixelSize: 20
            font.weight: Theme.expressive ? Font.Bold : Font.Medium
        }
        Switch {
            visible: page.hasSwitch
            checked: page.switchOn
            onToggled: on => page.switchToggled(on)
        }
    }

    Label {
        Layout.fillWidth: true
        Layout.leftMargin: 4
        Layout.rightMargin: 4
        visible: page.section !== "" && !page.empty
        text: page.section
        font.pixelSize: 13
        font.weight: Font.DemiBold
        color: Theme.primary
    }

    ColumnLayout {
        id: list
        Layout.fillWidth: true
        Layout.topMargin: -8
        visible: !page.empty
        spacing: page.rowSpacing
    }

    Label {
        Layout.fillWidth: true
        Layout.margins: 24
        visible: page.empty
        horizontalAlignment: Text.AlignHCenter
        text: page.emptyText
        color: Theme.fgVariant
    }

    Item { Layout.fillHeight: true }

    // pill text link
    Rectangle {
        visible: page.more !== ""
        Layout.alignment: Qt.AlignLeft
        implicitWidth: moreRow.implicitWidth + 32
        implicitHeight: 40
        radius: 20
        color: "transparent"
        StateLayer { area: moreMouse; tint: Theme.primary }
        Row {
            id: moreRow
            anchors.centerIn: parent
            spacing: 8
            Label { text: page.more; font.pixelSize: 14; font.weight: Font.DemiBold; color: Theme.primary; anchors.verticalCenter: parent.verticalCenter }
            Sym { name: "open_in_new"; size: 18; color: Theme.primary; anchors.verticalCenter: parent.verticalCenter }
        }
        MouseArea {
            id: moreMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: page.moreClicked()
        }
    }
}
