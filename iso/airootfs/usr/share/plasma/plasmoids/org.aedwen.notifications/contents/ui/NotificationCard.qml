// One notification: app icon tile, app name and age, summary, body, and its
// action buttons. Click runs the default action; the close button removes it.
import QtQuick
import QtQuick.Layouts
import org.kde.notificationmanager as NotificationManager
import org.aedwen.ui

Rectangle {
    id: card
    required property int index
    required property var model
    required property var notifications

    readonly property var actionNames: model.actionNames || []
    readonly property var actionLabels: model.actionLabels || []

    implicitHeight: content.implicitHeight + 24
    radius: Theme.rCard
    color: Theme.sc

    function age(d) {
        if (!d) return ""
        const s = (Date.now() - d.getTime()) / 1000
        if (s < 60) return i18nc("notification age", "now")
        if (s < 3600) return i18nc("notification age, minutes", "%1m", Math.floor(s / 60))
        if (s < 86400) return i18nc("notification age, hours", "%1h", Math.floor(s / 3600))
        return d.toLocaleDateString(Qt.locale(), Locale.ShortFormat)
    }

    StateLayer { area: mouse }
    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        enabled: card.model.hasDefaultAction === true
        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: card.notifications.invokeDefaultAction(card.notifications.index(card.index, 0),
                                                          NotificationManager.Notifications.Close)
    }

    RowLayout {
        id: content
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 12
        spacing: 12

        AppIcon {
            Layout.alignment: Qt.AlignTop
            source: card.model.applicationIconName || card.model.iconName || "preferences-desktop-notification"
            size: 34
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 3
            RowLayout {
                Layout.fillWidth: true
                Label {
                    Layout.fillWidth: true
                    role: "caption"
                    text: card.model.applicationName || ""
                }
                Label {
                    role: "caption"
                    text: card.age(card.model.updated || card.model.created)
                }
                IconButton {
                    icon: "close"
                    size: 24
                    iconSize: 16
                    visible: mouse.containsMouse || hovered
                    readonly property bool hovered: false
                    onClicked: card.notifications.close(card.notifications.index(card.index, 0))
                }
            }
            Label {
                Layout.fillWidth: true
                text: card.model.summary || ""
                font.weight: Font.Medium
                wrapMode: Text.Wrap
                maximumLineCount: 2
            }
            Label {
                Layout.fillWidth: true
                visible: text !== ""
                text: card.model.body || ""
                textFormat: Text.StyledText
                role: "label"
                color: Theme.fgVariant
                wrapMode: Text.Wrap
                maximumLineCount: 4
                onLinkActivated: link => Qt.openUrlExternally(link)
            }
            Flow {
                Layout.fillWidth: true
                Layout.topMargin: 4
                visible: card.actionNames.length > 0
                spacing: 6
                Repeater {
                    model: card.actionNames
                    PillButton {
                        required property int index
                        required property string modelData
                        visible: modelData !== "default"
                        kind: "tonal"
                        compact: true
                        text: card.actionLabels[index] || modelData
                        onClicked: card.notifications.invokeAction(card.notifications.index(card.index, 0), modelData,
                                                                   NotificationManager.Notifications.Close)
                    }
                }
            }
        }
    }
}
