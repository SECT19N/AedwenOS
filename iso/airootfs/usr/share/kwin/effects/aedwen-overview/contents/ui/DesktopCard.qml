// A desktop in the Overview strip: a live miniature (wallpaper + windows)
// with rounded corners, its name below. Current desktop: 2 px accent ring
// at 70 %, the design's focused-window border. Drop a window on it to move
// the window there; hover shows a remove button.
import QtQuick
import Qt5Compat.GraphicalEffects
import org.kde.kwin as KWinComponents
import org.aedwen.ui

Column {
    id: card

    property QtObject cardDesktop
    property int cardIndex
    property real cardHeight
    property QtObject screen
    property QtObject windowModel
    property bool current
    property bool removable

    signal activated()
    signal removeRequested()

    spacing: 6

    Item {
        width: card.width
        height: card.cardHeight

        // miniature at full output size, scaled down
        Item {
            id: mini
            width: card.screen.geometry.width
            height: card.screen.geometry.height
            scale: card.cardHeight / card.screen.geometry.height
            transformOrigin: Item.TopLeft
            layer.enabled: true
            layer.textureSize: Qt.size(card.width, card.cardHeight)
            layer.effect: OpacityMask {
                maskSource: Rectangle {
                    width: mini.width
                    height: mini.height
                    // Theme.rTile at card size, independent of the scale
                    radius: Theme.rTile / mini.scale
                }
            }

            KWinComponents.DesktopBackground {
                anchors.fill: parent
                activity: KWinComponents.Workspace.currentActivity
                desktop: card.cardDesktop
                outputName: card.screen.name
            }
            Repeater {
                model: KWinComponents.WindowFilterModel {
                    activity: KWinComponents.Workspace.currentActivity
                    desktop: card.cardDesktop
                    screenName: card.screen.name
                    windowModel: card.windowModel
                    windowType: KWinComponents.WindowFilterModel.Normal | KWinComponents.WindowFilterModel.Dialog
                }
                KWinComponents.WindowThumbnail {
                    wId: model.window.internalId
                    x: model.window.x - card.screen.geometry.x
                    y: model.window.y - card.screen.geometry.y
                    width: model.window.width
                    height: model.window.height
                    z: model.window.stackingOrder
                    visible: !model.window.minimized
                }
            }
        }

        // ring: accent when current, brighter outline on hover / drag-over
        Rectangle {
            anchors.fill: parent
            anchors.margins: -3
            radius: Theme.rTile + 3
            color: "transparent"
            border.width: 2
            border.color: card.current ? Theme.alpha(Theme.primary, 0.7)
                        : hover.hovered || drop.containsDrag ? Theme.alpha(Theme.fg, 0.4)
                        : Theme.alpha(Theme.fg, 0.12)
            Behavior on border.color { ColorAnimation { duration: Theme.durShort } }
        }

        HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
        TapHandler { onTapped: card.activated() }

        DropArea {
            id: drop
            anchors.fill: parent
            onDropped: ev => {
                ev.accepted = true
                // a KWin::Window; no desktops = on all desktops
                const w = ev.source
                if (!w.desktops || w.desktops.length === 0 || w.desktops.indexOf(card.cardDesktop) !== -1) {
                    ev.action = Qt.IgnoreAction
                    return
                }
                w.desktops = [card.cardDesktop]
            }
        }

        // remove
        Rectangle {
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.margins: 6
            width: 24
            height: 24
            radius: 12
            visible: card.removable && (hover.hovered || closeHover.hovered)
            color: closeHover.hovered ? Theme.errC : Theme.alpha(Theme.surface, 0.85)
            Sym {
                anchors.centerIn: parent
                name: "close"
                size: 16
                color: closeHover.hovered ? Theme.errCFg : Theme.fg
            }
            HoverHandler { id: closeHover; cursorShape: Qt.PointingHandCursor }
            TapHandler { onTapped: card.removeRequested() }
        }
    }

    Text {
        width: card.width
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight
        text: card.cardDesktop ? card.cardDesktop.name : ""
        color: card.current ? Theme.fg : Theme.alpha(Theme.fg, 0.72)
        font.family: Theme.font
        font.pixelSize: 12
        font.weight: card.current ? Font.DemiBold : Font.Normal
    }
}
