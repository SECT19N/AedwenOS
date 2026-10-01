// Keyboard step: keyboard model dropdown, Layout and Variant lists side by
// side, and a field to try the chosen layout.
import io.calamares.core 1.0
import io.calamares.ui 1.0
import QtQuick
import QtQuick.Layouts
import "."

Rectangle {
    id: page
    color: Theme.surface

    component Column_ : ColumnLayout {
        property string heading
        property alias model: list.model
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: 6
        Text {
            leftPadding: 4
            text: parent.heading
            color: Theme.fgVariant
            font.family: Theme.font
            font.pixelSize: 12
            font.weight: Font.DemiBold
        }
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: Theme.rCard
            color: Theme.scLow
            ListView {
                id: list
                anchors.fill: parent
                anchors.margins: 4
                clip: true
                spacing: 2
                boundsBehavior: Flickable.StopAtBounds
                currentIndex: model.currentIndex
                onCountChanged: positionViewAtIndex(Math.max(0, model.currentIndex), ListView.Center)
                Component.onCompleted: positionViewAtIndex(Math.max(0, model.currentIndex), ListView.Center)
                delegate: ListRow {
                    width: list.width
                    title: label
                    selected: index === list.model.currentIndex
                    onClicked: list.model.currentIndex = index
                }
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 32
        anchors.topMargin: 28
        anchors.bottomMargin: 8
        spacing: 16

        PageHeader {
            Layout.fillWidth: true
            title: qsTr("Choose a keyboard layout")
            description: qsTr("Pick the layout printed on your keys. You can add more later.")
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 12
            Column_ { heading: qsTr("Layout"); model: config.keyboardLayoutsModel; Layout.preferredWidth: 12 }
            Column_ { heading: qsTr("Variant"); model: config.keyboardVariantsModel; Layout.preferredWidth: 10 }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 12
            OutlinedField {
                Layout.fillWidth: true
                pill: true
                leadingIcon: "keyboard"
                placeholder: qsTr("Type here to test your keyboard")
            }
            Dropdown {
                Layout.preferredWidth: 260
                icon: "keyboard"
                model: config.keyboardModelsModel
                textRole: "label"
                currentIndex: config.keyboardModelsModel.currentIndex
                currentText: config.keyboardModelsModel.data(config.keyboardModelsModel.index(currentIndex, 0), Qt.DisplayRole) || ""
                onActivated: (i) => config.keyboardModelsModel.currentIndex = i
            }
        }
    }
}
