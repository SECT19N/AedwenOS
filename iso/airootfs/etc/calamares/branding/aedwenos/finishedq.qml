// Finished step: a primary check badge in the asymmetric shape, then
// either "installed, restart now" or the failure details.
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
        width: Math.min(parent.width - 64, 520)
        spacing: 16

        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            width: 112
            height: 112
            color: config.failed ? Theme.errC : Theme.primary
            topLeftRadius: 56
            topRightRadius: 56
            bottomRightRadius: 56
            bottomLeftRadius: 29
            Sym {
                anchors.centerIn: parent
                name: config.failed ? "error" : "check"
                size: 60
                color: config.failed ? Theme.errCFg : Theme.primaryFg
                font.variableAxes: ({ "wght": 600, "opsz": 48 })
            }
        }
        Text {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: config.failed ? qsTr("Installation failed") : qsTr("%1 is installed").arg(Branding.string(Branding.ProductName))
            wrapMode: Text.WordWrap
            color: Theme.fg
            font.family: Theme.font
            font.pixelSize: 38
            font.weight: Font.Bold
        }
        Text {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: config.failed ? config.failureMessage
                : qsTr("Remove the USB drive, then restart. Your new system starts with everything you chose here.")
            wrapMode: Text.WordWrap
            lineHeight: 1.15
            color: Theme.fgVariant
            font.family: Theme.font
            font.pixelSize: 15
        }

        // Failure details from the failing job, in a scrollable monospace box.
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 140
            visible: config.failed && config.failureDetails !== ""
            radius: Theme.rInner
            color: Theme.scLow
            Flickable {
                anchors.fill: parent
                anchors.margins: 12
                contentHeight: details.implicitHeight
                clip: true
                Text {
                    id: details
                    width: parent.width
                    text: config.failureDetails
                    wrapMode: Text.WrapAnywhere
                    color: Theme.fg
                    font.family: Theme.mono
                    font.pixelSize: 12
                }
            }
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 8
            spacing: 8
            PillButton {
                kind: "text"
                text: config.failed ? qsTr("Close") : qsTr("Keep trying it out")
                onClicked: ViewManager.quit()
            }
            PillButton {
                visible: !config.failed
                icon: "restart_alt"
                text: qsTr("Restart now")
                onClicked: config.doRestart(true)
            }
        }
    }
}
