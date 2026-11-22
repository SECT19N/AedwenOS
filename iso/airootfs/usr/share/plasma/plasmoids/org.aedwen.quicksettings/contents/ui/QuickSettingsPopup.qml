// Popup (Desktop design: QUICK SETTINGS): now-playing card, a two-column
// grid of tiles, sliders, removable drives, then a footer card with battery
// status, keyboard layout and a gear that opens System Settings. Holding a
// tile with a chevron opens its details page (DetailPage.qml), which slides
// over the main page.
import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.aedwen.ui
import org.aedwen.shell

Item {
    id: popup
    required property var quickSettings

    // design: 380 px wide (pop.qs.w), 16 px padding, height follows content
    Layout.minimumWidth: 380
    Layout.preferredWidth: 380
    Layout.minimumHeight: Math.max(main.implicitHeight, stack.depth > 1 ? 420 : 0) + 42
    Layout.preferredHeight: Layout.minimumHeight

    function openPage(file) {
        stack.push(Qt.resolvedUrl(file), { back: () => stack.pop() })
    }

    Connections {
        target: popup.quickSettings
        function onExpandedChanged() {
            if (!popup.quickSettings.expanded)
                stack.pop(null, QQC2.StackView.Immediate)
        }
    }

    QQC2.StackView {
        id: stack
        anchors.fill: parent
        anchors.margins: 16
        // room for the resize grip in the bottom-left corner
        anchors.bottomMargin: 26
        initialItem: main
        // M3 shared-axis (x): slide + fade
        pushEnter: Transition {
            NumberAnimation { property: "x"; from: 32; to: 0; duration: Theme.durMed; easing.bezierCurve: Theme.standard; easing.type: Easing.BezierSpline }
            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.durMed }
        }
        pushExit: Transition { NumberAnimation { property: "opacity"; to: 0; duration: Theme.durShort } }
        popEnter: Transition {
            NumberAnimation { property: "x"; from: -32; to: 0; duration: Theme.durMed; easing.bezierCurve: Theme.standard; easing.type: Easing.BezierSpline }
            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.durMed }
        }
        popExit: Transition { NumberAnimation { property: "opacity"; to: 0; duration: Theme.durShort } }
    }

    ColumnLayout {
        id: main
        spacing: 16

        Loader {
            id: media
            Layout.fillWidth: true
            source: Qt.resolvedUrl("sections/Media.qml")
            visible: status === Loader.Ready && item.available
        }

        // design: auto-fill columns of at least 160 px -> two in the 380 px panel
        GridLayout {
            Layout.fillWidth: true
            columns: Math.max(1, Math.floor((width + 8) / (160 + 8)))
            rowSpacing: 8
            columnSpacing: 8
            Repeater {
                model: Plasmoid.configuration.tiles
                Loader {
                    required property string modelData
                    source: Qt.resolvedUrl("tiles/" + modelData + ".qml")
                    visible: status === Loader.Ready
                    Layout.fillWidth: true
                    Layout.preferredHeight: 68
                    Layout.preferredWidth: 1
                    onLoaded: if (item.hasOwnProperty("openPage")) item.openPage = popup.openPage
                    onStatusChanged: if (status === Loader.Error)
                        console.warn("aedwen quicksettings: tile", modelData, "failed to load")
                }
            }
        }

        Repeater {
            model: Plasmoid.configuration.sliders
            Loader {
                required property string modelData
                Layout.fillWidth: true
                source: Qt.resolvedUrl("sliders/" + modelData + ".qml")
                visible: status === Loader.Ready && item.available
            }
        }

        Loader {
            id: drives
            Layout.fillWidth: true
            source: Qt.resolvedUrl("sections/Drives.qml")
            visible: status === Loader.Ready && item.available
        }

        // footer card: battery, keyboard layout, settings
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: footer.implicitHeight + 16
            radius: Theme.rCard
            color: Theme.scHigh
            RowLayout {
                id: footer
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 8
                anchors.topMargin: 8
                anchors.bottomMargin: 8
                spacing: 10
                Loader {
                    id: battery
                    source: Qt.resolvedUrl("indicators/Battery.qml")
                    visible: status === Loader.Ready && item.shown
                    onLoaded: { item.color = Theme.fgVariant; item.showPercent = false; item.size = 20 }
                }
                Label {
                    Layout.fillWidth: true
                    visible: battery.visible
                    text: battery.item ? battery.item.summary : ""
                    color: Theme.fgVariant
                    font.pixelSize: 13
                }
                Item { Layout.fillWidth: true; visible: !battery.visible }
                Loader {
                    source: Qt.resolvedUrl("sections/KeyboardLayout.qml")
                    visible: status === Loader.Ready && item.available
                }
                IconButton {
                    icon: "settings"
                    size: 40
                    iconSize: 21
                    tooltip: i18n("Settings")
                    onClicked: Shell.openSettings("")
                }
            }
        }
    }

    // design: the panel opens from the top-right, so its grip is bottom-left
    ResizeGrip { edges: Qt.BottomEdge | Qt.LeftEdge }
}
