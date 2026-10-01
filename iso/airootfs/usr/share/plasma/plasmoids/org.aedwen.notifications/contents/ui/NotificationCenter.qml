import QtQuick
import QtQuick.Layouts
import org.kde.notificationmanager as NotificationManager
import org.aedwen.ui

Item {
    id: nc
    required property var center
    required property var model

    Layout.minimumWidth: 372
    Layout.preferredWidth: 372
    Layout.minimumHeight: 420
    Layout.preferredHeight: 620

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 6
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 4
            Label { role: "title"; text: i18n("Notifications"); Layout.fillWidth: true }
            PillButton {
                kind: "text"
                compact: true
                text: i18n("Clear all")
                visible: list.count > 0
                onClicked: nc.model.clear(NotificationManager.Notifications.ClearExpired)
            }
        }

        ListView {
            id: list
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 6
            model: nc.model
            boundsBehavior: Flickable.StopAtBounds
            add: Transition { NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.durMed } }
            remove: Transition { NumberAnimation { property: "opacity"; to: 0; duration: Theme.durShort } }
            displaced: Transition { NumberAnimation { property: "y"; duration: Theme.durMed; easing.type: Easing.OutCubic } }
            delegate: NotificationCard {
                width: list.width
                notifications: nc.model
            }

            Column {
                anchors.centerIn: parent
                visible: list.count === 0
                spacing: 8
                Sym { anchors.horizontalCenter: parent.horizontalCenter; name: "notifications_off"; size: 32; color: Theme.fgVariant }
                Label { text: i18n("No new notifications"); color: Theme.fgVariant }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 52
            radius: Theme.rCard
            color: Theme.sc
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 10
                spacing: 10
                Sym { name: "do_not_disturb_on"; size: 20 }
                Label { text: i18n("Do not disturb"); Layout.fillWidth: true }
                Switch {
                    compact: true
                    checked: nc.center.dnd
                    onToggled: checked => nc.center.setDnd(checked)
                }
            }
        }
    }
}
