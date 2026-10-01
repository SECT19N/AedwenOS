// Bottom bar of each step: step counter on the left, text "Back" and a
// filled primary pill for "Next" / "Install now" on the right.
import io.calamares.ui 1.0
import io.calamares.core 1.0
import QtQuick
import QtQuick.Layouts
import "."

Rectangle {
    id: bar
    color: Theme.surface
    height: 64

    // Calamares' labels carry "&" mnemonics ("&Next"); drop them.
    function plain(s) { return s ? s.replace(/&(?=\S)/g, "") : "" }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 32
        anchors.rightMargin: 32
        spacing: 8

        Text {
            Layout.fillWidth: true
            // The finished page is the last model row and isn't counted as a step.
            visible: ViewManager.backAndNextVisible && ViewManager.currentStepIndex < ViewManager.rowCount() - 1
            text: qsTr("Step %1 of %2").arg(ViewManager.currentStepIndex + 1).arg(ViewManager.rowCount() - 1)
            color: Theme.fgVariant
            font.family: Theme.mono
            font.pixelSize: 12
        }
        Item { Layout.fillWidth: true; visible: !ViewManager.backAndNextVisible }

        PillButton {
            kind: "text"
            text: ViewManager.quitLabel ? bar.plain(ViewManager.quitLabel) : qsTr("Cancel")
            // Shown while installing ("Cancel"); the finished page has its own buttons.
            visible: ViewManager.quitVisible && !ViewManager.backAndNextVisible
                     && ViewManager.currentStepIndex < ViewManager.rowCount() - 1
            enabled: ViewManager.quitEnabled
            onClicked: ViewManager.quit()
        }
        PillButton {
            kind: "text"
            text: bar.plain(ViewManager.backLabel)
            visible: ViewManager.backAndNextVisible
            enabled: ViewManager.backEnabled
            onClicked: ViewManager.back()
        }
        PillButton {
            kind: "filled"
            text: bar.plain(ViewManager.nextLabel)
            visible: ViewManager.backAndNextVisible
            enabled: ViewManager.nextEnabled
            onClicked: ViewManager.next()
        }
    }
}
