// 6-column grid of apps (pinned). Drag an app to the dock to pin it there;
// right-click to unpin.
import QtQuick
import org.kde.plasma.extras as PlasmaExtras
import org.aedwen.ui

GridView {
    id: grid
    property var favorites
    signal launched()

    clip: true
    cellWidth: Math.floor(width / 6)
    cellHeight: 92
    boundsBehavior: Flickable.StopAtBounds
    keyNavigationEnabled: true

    delegate: Item {
        id: cellItem
        required property int index
        required property var model
        width: grid.cellWidth
        height: grid.cellHeight

        Rectangle {
            anchors.fill: parent
            anchors.margins: 2
            radius: Theme.rCard - 4
            color: grid.currentIndex === cellItem.index && grid.activeFocus ? Theme.secC : "transparent"
            StateLayer { area: mouse }
        }
        Column {
            anchors.centerIn: parent
            spacing: 7
            AppIcon {
                anchors.horizontalCenter: parent.horizontalCenter
                source: cellItem.model.decoration
                size: 44
                hovered: mouse.containsMouse
            }
            Label {
                width: grid.cellWidth - 8
                horizontalAlignment: Text.AlignHCenter
                role: "caption"
                color: Theme.fg
                text: cellItem.model.display
            }
        }
        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            cursorShape: Qt.PointingHandCursor
            drag.target: dragProxy
            onClicked: mouse => {
                if (mouse.button === Qt.RightButton) {
                    menu.open(mouse.x, mouse.y)
                } else if (grid.model.trigger(cellItem.index, "", null) !== false) {
                    grid.launched()
                }
            }
        }
        Item {
            id: dragProxy
            Drag.active: mouse.drag.active
            Drag.dragType: Drag.Automatic
            Drag.supportedActions: Qt.CopyAction | Qt.LinkAction
            Drag.mimeData: ({ "text/uri-list": String(cellItem.model.url || "") })
        }
        PlasmaExtras.Menu {
            id: menu
            visualParent: cellItem
            PlasmaExtras.MenuItem {
                text: i18n("Unpin from Launcher")
                icon: "window-unpin"
                onClicked: grid.favorites.removeFavorite(cellItem.model.favoriteId)
            }
        }
    }
    Keys.onReturnPressed: if (currentIndex >= 0 && model.trigger(currentIndex, "", null) !== false) launched()
}
