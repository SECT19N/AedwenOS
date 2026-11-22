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
    // row of the root model shown under "All apps": row 0 is "All
    // Applications", the following rows (skipping separators) are the
    // categories (Development, Internet, ...)
    property int category: 0
    readonly property bool searching: search.text !== ""
    readonly property var categories: {
        const m = popup.launcher.rootModel
        const out = []
        for (let i = 0; i < m.count; ++i) {
            const sub = m.modelForRow(i)
            if (sub && sub.count > 0)
                out.push({ row: i, name: i === 0 ? i18n("All") : String(m.data(m.index(i, 0), Qt.DisplayRole)) })
        }
        return out
    }

    Layout.minimumWidth: 3 * 88 + 16      // three grid columns
    Layout.preferredWidth: 560
    Layout.minimumHeight: 420
    Layout.preferredHeight: 600

    KCoreAddons.KUser { id: kuser }
    Sessions.SessionManagement { id: sessions }

    Connections {
        target: popup.launcher
        function onExpandedChanged() {
            if (popup.launcher.expanded) {
                search.text = ""
                popup.showAll = false
                popup.category = 0
                search.input.forceActiveFocus()
            }
        }
    }
    Component.onCompleted: launcher.searchField = search

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 8
        // the resize grip sits in the bottom-right corner: keep the power
        // button clear of it
        anchors.bottomMargin: 26
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

        // categories of the all-apps list
        Flickable {
            visible: !popup.searching && popup.showAll && popup.categories.length > 1
            Layout.fillWidth: true
            implicitHeight: chips.implicitHeight
            contentWidth: chips.implicitWidth
            contentHeight: chips.implicitHeight
            flickableDirection: Flickable.HorizontalFlick
            boundsBehavior: Flickable.StopAtBounds
            clip: true
            Row {
                id: chips
                spacing: 6
                Repeater {
                    model: popup.categories
                    PillButton {
                        required property var modelData
                        compact: true
                        kind: popup.category === modelData.row ? "tonal" : "text"
                        text: modelData.name
                        onClicked: popup.category = modelData.row
                    }
                }
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
        // all apps, or one category of them
        AppList {
            visible: !popup.searching && popup.showAll
            Layout.fillWidth: true
            Layout.fillHeight: true
            model: popup.launcher.rootModel.count > popup.category ? popup.launcher.rootModel.modelForRow(popup.category) : null
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
            Layout.rightMargin: 14
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

    // design: drag the bottom-right corner to resize; the grid reflows
    ResizeGrip { edges: Qt.BottomEdge | Qt.RightEdge }
}
