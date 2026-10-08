// Lock screen clock: Breeze's Clock (org.kde.breeze.components) with the
// AedwenOS display type -- a heavy, tight time over the date. Same layout
// and interface (LockScreenUi positions it and drops a shadow on it).
// Based on plasma-workspace's Clock.qml, LGPL-2.0-or-later.
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.clock as PlasmaClock
import org.aedwen.ui as Ae

ColumnLayout {
    id: root
    readonly property bool softwareRendering: GraphicsInfo.api === GraphicsInfo.Software
    spacing: 4

    Ae.Label {
        text: Qt.formatTime(timeSource.dateTime, Qt.locale(), Locale.ShortFormat)
        style: root.softwareRendering ? Text.Outline : Text.Normal
        styleColor: root.softwareRendering ? Ae.Theme.surface : "transparent"
        color: "white"
        font.pixelSize: 112
        font.weight: Font.Bold
        font.letterSpacing: -4
        font.features: { "tnum": 1 }
        Layout.alignment: Qt.AlignHCenter
    }
    Ae.Label {
        text: Qt.formatDate(timeSource.dateTime, Qt.locale(), "dddd d MMMM")
        style: root.softwareRendering ? Text.Outline : Text.Normal
        styleColor: root.softwareRendering ? Ae.Theme.surface : "transparent"
        color: "white"
        font.pixelSize: 22
        font.weight: Font.Medium
        Layout.alignment: Qt.AlignHCenter
    }

    PlasmaClock.Clock {
        id: timeSource
        trackSeconds: Qt.locale().timeFormat(Locale.ShortFormat).includes("s")
    }
}
