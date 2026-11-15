// Popup: 3-column tile grid, sliders, removable drives, then battery status,
// keyboard layout and a gear that opens System Settings. Tiles can open a
// detail page (e.g. the network list) that slides over the main page.
import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.aedwen.ui
import org.aedwen.shell

Item {
    id: popup
    required property var quickSettings

    Layout.minimumWidth: 356
    Layout.preferredWidth: 356
    Layout.minimumHeight: Math.max(main.implicitHeight, stack.depth > 1 ? 420 : 0) + 16
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
        anchors.margins: 8
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

        GridLayout {
            Layout.fillWidth: true
            columns: 3
            rowSpacing: 8
            columnSpacing: 8
            Repeater {
                model: Plasmoid.configuration.tiles
                Loader {
                    required property string modelData
                    source: Qt.resolvedUrl("tiles/" + modelData + ".qml")
                    visible: status === Loader.Ready
                    Layout.fillWidth: true
                    Layout.preferredHeight: 76
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

        Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Theme.outlineV }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            Loader {
                id: battery
                source: Qt.resolvedUrl("indicators/Battery.qml")
                visible: status === Loader.Ready && item.shown
                onLoaded: { item.color = Theme.fgVariant; item.showPercent = false }
            }
            Label {
                Layout.fillWidth: true
                visible: battery.visible
                text: battery.item ? battery.item.summary : ""
                color: Theme.fgVariant
                role: "label"
            }
            Item { Layout.fillWidth: true; visible: !battery.visible }
            Loader {
                source: Qt.resolvedUrl("sections/KeyboardLayout.qml")
                visible: status === Loader.Ready && item.available
            }
            IconButton {
                icon: "settings"
                onClicked: Shell.openSettings("")
            }
        }
    }

    // design: the panel opens from the top-right, so its grip is bottom-left
    ResizeGrip { edges: Qt.BottomEdge | Qt.LeftEdge }
}
