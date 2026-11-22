// Vertical list of apps / search results with icons; Enter launches the
// current one, right-click pins or unpins.
import QtQuick
import org.kde.plasma.extras as PlasmaExtras
import org.aedwen.ui
import org.aedwen.shell

ListView {
    id: list
    property var favorites
    property bool showSubtitle: false
    signal launched()
    signal upFromTop()

    clip: true
    spacing: 2
    boundsBehavior: Flickable.StopAtBounds
    keyNavigationEnabled: true
    highlightMoveDuration: 0
    currentIndex: 0

    function launchCurrent() {
        if (count > 0 && model.trigger(Math.max(0, currentIndex), "", null) !== false)
            launched()
    }

    section.property: showSubtitle ? "" : "display"
    section.criteria: ViewSection.FirstCharacter
    section.delegate: Label {
        required property string section
        text: section.toUpperCase()
        role: "caption"
        color: Theme.primary
        font.weight: Font.DemiBold
        leftPadding: 12
        height: 28
    }

    delegate: ListRow {
        id: row
        required property int index
        required property var model
        width: list.width
        title: model.display || ""
        subtitle: list.showSubtitle ? (model.description || "") : ""
        appIcon: model.decoration
        selected: list.currentIndex === index && (list.activeFocus || list.showSubtitle)
        activeFocusOnTab: false          // the list is the tab stop
        showRing: list.currentIndex === index && list.activeFocus
        onClicked: { list.currentIndex = index; list.launchCurrent() }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.RightButton
            onClicked: mouse => menu.open(mouse.x, mouse.y)
        }
        PlasmaExtras.Menu {
            id: menu
            visualParent: row
            PlasmaExtras.MenuItem {
                visible: !!row.model.favoriteId
                text: i18n("Pin to Dock")
                icon: "pin"
                onClicked: Shell.pinToDock(row.model.favoriteId)
            }
            PlasmaExtras.MenuItem {
                readonly property bool pinned: row.model.favoriteId ? list.favorites.isFavorite(row.model.favoriteId) : false
                visible: !!row.model.favoriteId
                text: pinned ? i18n("Unpin from Launcher") : i18n("Pin to Launcher")
                icon: pinned ? "window-unpin" : "window-pin"
                onClicked: pinned ? list.favorites.removeFavorite(row.model.favoriteId)
                                  : list.favorites.addFavorite(row.model.favoriteId, -1)
            }
        }
    }
    Keys.onReturnPressed: launchCurrent()
    Keys.onEnterPressed: launchCurrent()
    Keys.onUpPressed: event => {
        if (currentIndex <= 0) upFromTop()
        else decrementCurrentIndex()
    }
}
