// Centred date and time (Desktop design: top bar) with the calendar popup.
// Formats follow the user's locale (12/24 h, date order, first weekday).
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.aedwen.ui

PlasmoidItem {
    id: root
    property date now: new Date()
    readonly property var locale: Qt.locale()

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    preferredRepresentation: compactRepresentation
    switchWidth: 300
    switchHeight: 300
    toolTipMainText: now.toLocaleDateString(locale, Locale.LongFormat)
    toolTipSubText: ""

    Timer {
        interval: Plasmoid.configuration.showSeconds ? 1000 : 1000 * (60 - new Date().getSeconds())
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: { root.now = new Date(); interval = Plasmoid.configuration.showSeconds ? 1000 : 60000 }
    }

    function timeString(d) {
        const fmt = locale.timeFormat(Locale.ShortFormat)
        return d.toLocaleTimeString(locale, Plasmoid.configuration.showSeconds
                                    ? locale.timeFormat(Locale.LongFormat).replace(/\s*t+$/, "") : fmt)
    }

    compactRepresentation: Item {
        Layout.minimumWidth: button.implicitWidth
        Layout.preferredWidth: button.implicitWidth
        PanelButton {
            id: button
            anchors.centerIn: parent
            active: root.expanded
            padding: 12
            onClicked: root.expanded = !root.expanded
            Label {
                visible: Plasmoid.configuration.showDate
                anchors.verticalCenter: parent.verticalCenter
                text: root.now.toLocaleDateString(root.locale, "ddd d MMM")
                color: root.expanded ? Theme.secCFg : Theme.fgVariant
                font.weight: Font.Medium
            }
            Label {
                anchors.verticalCenter: parent.verticalCenter
                text: root.timeString(root.now)
                color: root.expanded ? Theme.secCFg : Theme.fg
                font.weight: Font.Medium
                font.features: { "tnum": 1 }
            }
        }
    }

    fullRepresentation: CalendarPopup { clock: root }
}
