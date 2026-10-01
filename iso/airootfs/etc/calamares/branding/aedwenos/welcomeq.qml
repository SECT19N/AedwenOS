// Welcome step: eagle in the asymmetric "morph" shape, title, language
// picker, and the requirement checks as chips (design: installer step 0).
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
        width: Math.min(parent.width - 64, 560)
        spacing: 18

        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            width: 104
            height: 104
            color: Theme.pc
            topLeftRadius: 52
            topRightRadius: 52
            bottomRightRadius: 52
            bottomLeftRadius: 29
            EagleMark {
                anchors.centerIn: parent
                width: 60
                height: 60
                tint: "pc-fg"
            }
        }
        Text {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: qsTr("Welcome to %1").arg(Branding.string(Branding.ProductName))
            wrapMode: Text.WordWrap
            color: Theme.fg
            font.family: Theme.font
            font.pixelSize: 38
            font.weight: Font.Bold
        }
        Text {
            Layout.alignment: Qt.AlignHCenter
            Layout.maximumWidth: 440
            horizontalAlignment: Text.AlignHCenter
            text: qsTr("Installing takes about 10 minutes. Nothing on this computer changes until you press Install now.")
            wrapMode: Text.WordWrap
            lineHeight: 1.15
            color: Theme.fgVariant
            font.family: Theme.font
            font.pixelSize: 15
        }
        Dropdown {
            Layout.alignment: Qt.AlignHCenter
            icon: "translate"
            model: config.languagesModel
            textRole: "label"
            currentIndex: config.localeIndex
            currentText: config.languagesModel.data(config.languagesModel.index(config.localeIndex, 0), Qt.DisplayRole) || ""
            onActivated: (i) => config.localeIndex = i
        }

        // Requirement checks: a chip per check; unmet ones turn red (mandatory)
        // or amber-ish tertiary (recommended) and show the reason.
        Flow {
            Layout.fillWidth: true
            Layout.topMargin: 6
            spacing: 8
            // Centre the chips: Flow has no alignment, so pad the left.
            leftPadding: Math.max(0, (width - chipRow.width) / 2)

            Row {
                id: chipRow
                spacing: 8
                Repeater {
                    model: config.requirementsModel
                    Rectangle {
                        height: 32
                        width: chip.implicitWidth + 20
                        radius: 8
                        color: satisfied ? "transparent" : (mandatory ? Theme.errC : Theme.terC)
                        border.width: satisfied ? 1 : 0
                        border.color: Theme.outlineV
                        Row {
                            id: chip
                            anchors.centerIn: parent
                            spacing: 6
                            Sym {
                                size: 18
                                fill: 1
                                name: satisfied ? "check_circle" : (mandatory ? "error" : "warning")
                                color: satisfied ? Theme.primary : (mandatory ? Theme.errCFg : Theme.terCFg)
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            Text {
                                text: satisfied ? details : negatedText
                                color: satisfied ? Theme.fg : (mandatory ? Theme.errCFg : Theme.terCFg)
                                font.family: Theme.font
                                font.pixelSize: 13
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                    }
                }
            }
        }
        Text {
            Layout.fillWidth: true
            visible: !config.requirementsModel.satisfiedMandatory
            horizontalAlignment: Text.AlignHCenter
            text: qsTr("This computer doesn't meet the minimum requirements for %1, so installation can't continue.").arg(Branding.string(Branding.ProductName))
            wrapMode: Text.WordWrap
            color: Theme.err
            font.family: Theme.font
            font.pixelSize: 13
        }
    }
}
