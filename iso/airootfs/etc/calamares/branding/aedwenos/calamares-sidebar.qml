// Installer step list ("Installer · Calamares" in the AedwenOS System
// Surfaces design): pill rows on the sc-low panel, the current step on a
// secondary-container pill, finished steps ticked.
import io.calamares.ui 1.0
import io.calamares.core 1.0
import QtQuick
import QtQuick.Layouts
import "."

Rectangle {
    id: sideBar
    color: Theme.scLow
    anchors.fill: parent

    // Module names that read better as the design's step names.
    readonly property var names: ({ "Partitions": qsTr("Disk") })

    ColumnLayout {
        anchors.fill: parent
        anchors.topMargin: 16
        anchors.bottomMargin: 14
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        spacing: 2

        Repeater {
            id: steps
            model: ViewManager
            Rectangle {
                id: step
                readonly property bool current: index === ViewManager.currentStepIndex
                readonly property bool done: index < ViewManager.currentStepIndex
                // The last row is the "finished" page; the design ends the list at Install.
                visible: index < steps.count - 1
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                radius: 20
                color: current ? Theme.secC : "transparent"
                Behavior on color { ColorAnimation { duration: 200 } }

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    spacing: 10
                    Sym {
                        anchors.verticalCenter: parent.verticalCenter
                        size: 18
                        fill: 1
                        name: step.done || ViewManager.currentStepIndex === steps.count - 1 ? "check_circle"
                            : step.current ? "radio_button_checked" : "radio_button_unchecked"
                        color: step.current ? Theme.secCFg : step.done ? Theme.primary : Theme.fgVariant
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: sideBar.names[display] || display
                        color: step.current ? Theme.secCFg : step.done ? Theme.fg : Theme.fgVariant
                        font.family: Theme.font
                        font.pixelSize: 14
                        font.weight: step.current ? Font.DemiBold : Font.Normal
                    }
                }
            }
        }

        Item { Layout.fillHeight: true }

        Text {
            Layout.leftMargin: 12
            text: Branding.string(Branding.ProductName) + " " + Branding.string(Branding.Version)
            color: Theme.fgVariant
            font.family: Theme.mono
            font.pixelSize: 11
            // Calamares' debug window, for testers (only with -d).
            MouseArea {
                anchors.fill: parent
                enabled: typeof debug !== "undefined" && debug.enabled
                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: debug.toggle()
            }
        }
    }
}
