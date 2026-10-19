// A window in the Overview grid, placed by KWin's ExpoLayout. The live
// thumbnail already carries the AedwenOS title bar and corners; on top of
// it: the design's 2 px ring (accent at 70 % for the active window), app
// icon + title below, a close button on hover. Click activates, middle-click
// closes, drag onto a desktop card moves the window to that desktop.
import QtQuick
import org.kde.kirigami as Kirigami
import org.kde.kwin as KWinComponents
import org.kde.kwin.private.effects
import org.aedwen.ui

ExpoCell {
    id: cell

    property QtObject cellWindow
    property QtObject screen
    readonly property bool active: KWinComponents.Workspace.activeWindow === cellWindow
    readonly property int captionHeight: 28

    signal activated()

    naturalX: cellWindow.x - screen.geometry.x
    naturalY: cellWindow.y - screen.geometry.y
    naturalWidth: cellWindow.width
    naturalHeight: cellWindow.height
    persistentKey: cellWindow.internalId
    bottomMargin: captionHeight + Theme.gap
    shouldLayout: !cellWindow.skipSwitcher

    Behavior on x { NumberAnimation { duration: effect.animationDuration; easing.type: Easing.OutCubic } }
    Behavior on y { NumberAnimation { duration: effect.animationDuration; easing.type: Easing.OutCubic } }
    Behavior on width { NumberAnimation { duration: effect.animationDuration; easing.type: Easing.OutCubic } }
    Behavior on height { NumberAnimation { duration: effect.animationDuration; easing.type: Easing.OutCubic } }

    contentItem: Item {
        id: slot
        // ExpoCell only positions its contentItem; it still needs a parent
        parent: cell
        visible: !cell.cellWindow.skipSwitcher
        z: drag.active ? 1000 : cell.cellWindow.stackingOrder

        // dragged as a whole; snaps back to the slot on release
        Item {
            id: body
            width: slot.width
            height: slot.height
            Behavior on x { enabled: !drag.active; NumberAnimation { duration: effect.animationDuration; easing.type: Easing.OutCubic } }
            Behavior on y { enabled: !drag.active; NumberAnimation { duration: effect.animationDuration; easing.type: Easing.OutCubic } }
            scale: drag.active ? 0.6 : 1
            Behavior on scale { NumberAnimation { duration: Theme.durShort } }

            Drag.active: drag.active
            Drag.source: cell.cellWindow
            Drag.hotSpot: Qt.point(width / 2, height / 2)
            Drag.proposedAction: Qt.MoveAction
            Drag.supportedActions: Qt.MoveAction

            KWinComponents.WindowThumbnail {
                anchors.fill: parent
                wId: cell.cellWindow.internalId
                opacity: cell.cellWindow.minimized ? 0.6 : 1
            }

            Rectangle {
                anchors.fill: parent
                anchors.margins: -4
                radius: Theme.rWin + 4
                color: "transparent"
                border.width: 2
                border.color: cell.active ? Theme.alpha(Theme.primary, 0.7)
                            : hover.hovered ? Theme.alpha(Theme.fg, 0.4) : "transparent"
                Behavior on border.color { ColorAnimation { duration: Theme.durShort } }
            }

            // close
            Rectangle {
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.margins: -10
                width: 28
                height: 28
                radius: 14
                visible: hover.hovered && !drag.active && cell.cellWindow.closeable
                color: closeHover.hovered ? Theme.errC : Theme.scHighest
                Sym {
                    anchors.centerIn: parent
                    name: "close"
                    size: 18
                    color: closeHover.hovered ? Theme.errCFg : Theme.fg
                }
                HoverHandler { id: closeHover; cursorShape: Qt.PointingHandCursor }
                TapHandler { onTapped: cell.cellWindow.closeWindow() }
            }
        }

        HoverHandler { id: hover }
        TapHandler {
            acceptedButtons: Qt.LeftButton
            onTapped: cell.activated()
        }
        TapHandler {
            acceptedButtons: Qt.MiddleButton
            onTapped: cell.cellWindow.closeWindow()
        }
        DragHandler {
            id: drag
            target: body
            onActiveChanged: {
                if (!active) {
                    body.Drag.drop()
                    body.x = 0
                    body.y = 0
                }
            }
        }

        // icon + title under the thumbnail
        Row {
            anchors.top: parent.bottom
            anchors.topMargin: Theme.gap
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 8
            visible: !drag.active
            Kirigami.Icon {
                anchors.verticalCenter: parent.verticalCenter
                width: 20
                height: 20
                source: cell.cellWindow.icon
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                width: Math.min(implicitWidth, slot.width - 28)
                elide: Text.ElideRight
                text: cell.cellWindow.caption
                color: cell.active ? Theme.fg : Theme.alpha(Theme.fg, 0.72)
                font.family: Theme.font
                font.pixelSize: 13
                font.weight: cell.active ? Font.DemiBold : Font.Medium
            }
        }
    }
}
