// The launcher popup: search, pinned grid / all apps / search results, and
// the user row with lock and power.
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.coreaddons as KCoreAddons
import org.kde.plasma.private.sessions as Sessions
import org.aedwen.ui
import org.aedwen.shell

Item {
    id: popup
    required property var launcher

    property bool showAll: false
    readonly property bool searching: search.text !== ""

    Layout.minimumWidth: 560
    Layout.preferredWidth: 560
    Layout.minimumHeight: 560
    Layout.preferredHeight: 600

    KCoreAddons.KUser { id: kuser }
    Sessions.SessionManagement { id: sessions }

    Connections {
        target: popup.launcher
        function onExpandedChanged() {
            if (popup.launcher.expanded) {
                search.text = ""
                popup.showAll = false
                search.input.forceActiveFocus()
            }
        }
    }
    Component.onCompleted: launcher.searchField = search

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 16

        SearchField {
            id: search
            Layout.fillWidth: true
            placeholder: i18n("Search apps, files, settings…")
            onAccepted: results.launchCurrent()
            onKeyPressed: event => {
                if (event.key === Qt.Key_Down) { results.forceActiveFocus(); event.accepted = true }
                else if (event.key === Qt.Key_Escape) { popup.launcher.expanded = false; event.accepted = true }
            }
        }

        RowLayout {
            visible: !popup.searching
            Layout.fillWidth: true
            Label {
                role: "title"
                text: popup.showAll ? i18n("All apps") : i18n("Pinned")
                Layout.fillWidth: true
            }
            PillButton {
                kind: "text"
                compact: true
                text: popup.showAll ? i18n("Pinned") : i18n("All apps")
                icon: popup.showAll ? "chevron_left" : "chevron_right"
                onClicked: popup.showAll = !popup.showAll
            }
        }

        // pinned
        AppGrid {
            visible: !popup.searching && !popup.showAll
            Layout.fillWidth: true
            Layout.fillHeight: true
            model: popup.launcher.rootModel.favoritesModel
            favorites: popup.launcher.rootModel.favoritesModel
            onLaunched: popup.launcher.expanded = false
        }
        // all apps (row 1 of the root model is "All Applications")
        AppList {
            visible: !popup.searching && popup.showAll
            Layout.fillWidth: true
            Layout.fillHeight: true
            model: popup.launcher.rootModel.count > 1 ? popup.launcher.rootModel.modelForRow(1) : null
            favorites: popup.launcher.rootModel.favoritesModel
            onLaunched: popup.launcher.expanded = false
        }
        // search results
        AppList {
            id: results
            visible: popup.searching
            Layout.fillWidth: true
            Layout.fillHeight: true
            showSubtitle: true
            model: popup.launcher.runnerModel.count ? popup.launcher.runnerModel.modelForRow(0) : null
            favorites: popup.launcher.rootModel.favoritesModel
            onLaunched: popup.launcher.expanded = false
            onUpFromTop: search.input.forceActiveFocus()
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 1
            color: Theme.outlineV
        }
        RowLayout {
            Layout.fillWidth: true
            spacing: 10
            Rectangle {
                implicitWidth: 32
                implicitHeight: 32
                radius: 16
                color: Theme.pc
                clip: true
                Label {
                    anchors.centerIn: parent
                    text: (kuser.fullName || kuser.loginName || "?").charAt(0).toUpperCase()
                    color: Theme.pcFg
                    font.weight: Font.DemiBold
                }
                Image {
                    anchors.fill: parent
                    source: kuser.faceIconUrl
                    visible: status === Image.Ready
                    fillMode: Image.PreserveAspectCrop
                }
            }
            Label {
                text: kuser.fullName || kuser.loginName
                font.weight: Font.Medium
                Layout.fillWidth: true
            }
            IconButton {
                icon: "settings"
                onClicked: { Shell.openSettings(""); popup.launcher.expanded = false }
            }
            IconButton {
                icon: "lock"
                onClicked: { popup.launcher.expanded = false; sessions.lock() }
            }
            IconButton {
                icon: "power_settings_new"
                onClicked: { popup.launcher.expanded = false; sessions.requestLogoutPrompt() }
            }
        }
    }
}
