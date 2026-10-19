// One output's Overview: blurred wallpaper, the desktop strip, and the
// current desktop's windows.
import QtQuick
import Qt5Compat.GraphicalEffects
import org.kde.kwin as KWinComponents
import org.kde.kwin.private.effects
import org.aedwen.ui

Item {
    id: root
    focus: true

    readonly property QtObject targetScreen: KWinComponents.SceneView.screen
    readonly property QtObject currentDesktop: KWinComponents.SceneView.currentDesktop
    // design: 8 px everywhere; the strip sits where the top bar floats
    readonly property int gap: Theme.gap
    readonly property real cardHeight: Math.round(Math.min(112, height * 0.11))
    readonly property real cardWidth: Math.round(cardHeight * targetScreen.geometry.width / targetScreen.geometry.height)
    // fades in once created, out while the effect deactivates
    property bool shown: false
    readonly property bool open: shown && effect.activated
    readonly property int desktopCount: desktopRepeater.count

    function switchTo(desktop) {
        if (desktop === currentDesktop)
            effect.deactivate()
        else
            KWinComponents.SceneView.currentDesktop = desktop
    }

    Component.onCompleted: Qt.callLater(() => root.shown = true)

    KWinComponents.WindowModel { id: allWindows }
    KWinComponents.VirtualDesktopModel { id: desktopModel }

    // Typing hands the text to KRunner (Alt+Space search) and closes.
    KWinComponents.DBusCall {
        id: krunner
        service: "org.kde.krunner"
        path: "/App"
        dbusInterface: "org.kde.krunner.App"
        method: "query"
    }

    Keys.onEscapePressed: effect.deactivate()
    Keys.onPressed: event => {
        if (event.text.length > 0 && event.text.trim().length > 0
                && !(event.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier))) {
            krunner.arguments = [event.text]
            krunner.call()
            effect.deactivate()
            event.accepted = true
        }
    }

    // --- background: wallpaper, blurred, under the design's acrylic tint ---
    Item {
        anchors.fill: parent
        KWinComponents.DesktopBackground {
            id: wallpaper
            activity: KWinComponents.Workspace.currentActivity
            desktop: root.currentDesktop
            outputName: root.targetScreen.name
            visible: false
        }
        FastBlur {
            anchors.fill: parent
            source: wallpaper
            radius: 64
        }
        Rectangle {
            anchors.fill: parent
            // --acr: the top bar / dock fill, a little denser behind windows
            color: Theme.alpha(Theme.dark ? Qt.darker(Theme.surface, 1.1) : Theme.surface, 0.55)
        }
        opacity: root.open ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: effect.animationDuration; easing.type: Easing.OutCubic } }

        TapHandler { onTapped: effect.deactivate() }
    }

    Item {
        id: content
        anchors.fill: parent
        opacity: root.open ? 1 : 0
        scale: root.open ? 1 : 1.04
        Behavior on opacity { NumberAnimation { duration: effect.animationDuration; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: effect.animationDuration; easing.type: Easing.OutCubic } }

        // --- desktop strip ---
        Row {
            id: strip
            anchors.horizontalCenter: parent.horizontalCenter
            y: root.gap * 2
            spacing: root.gap * 2

            Repeater {
                id: desktopRepeater
                model: desktopModel
                DesktopCard {
                    required property QtObject desktop
                    required property int index
                    cardDesktop: desktop
                    cardIndex: index
                    width: root.cardWidth
                    cardHeight: root.cardHeight
                    screen: root.targetScreen
                    windowModel: allWindows
                    current: desktop === root.currentDesktop
                    removable: root.desktopCount > 1
                    onActivated: root.switchTo(desktop)
                    onRemoveRequested: desktopModel.remove(index)
                }
            }

            // + new desktop (drop a window on it to move the window there)
            Item {
                width: root.cardWidth * 0.5
                height: root.cardHeight
                visible: root.desktopCount < desktopModel.maximum
                Rectangle {
                    anchors.fill: parent
                    radius: Theme.rTile
                    color: addHover.hovered || addDrop.containsDrag ? Theme.alpha(Theme.fg, 0.12) : Theme.alpha(Theme.fg, 0.06)
                    border.width: 1
                    border.color: Theme.alpha(Theme.fg, 0.1)
                    Behavior on color { ColorAnimation { duration: Theme.durShort } }
                }
                Sym {
                    anchors.centerIn: parent
                    name: "add"
                    size: 28
                    color: addHover.hovered ? Theme.fg : Theme.alpha(Theme.fg, 0.72)
                }
                HoverHandler { id: addHover; cursorShape: Qt.PointingHandCursor }
                TapHandler {
                    onTapped: KWinComponents.SceneView.currentDesktop = desktopModel.create(root.desktopCount)
                }
                DropArea {
                    id: addDrop
                    anchors.fill: parent
                    onDropped: drop => {
                        drop.accepted = true
                        drop.source.desktops = [desktopModel.create(root.desktopCount)]
                    }
                }
            }
        }

        // --- this desktop's windows ---
        ExpoLayout {
            id: heap
            anchors.fill: parent
            anchors.topMargin: strip.y + strip.height + root.gap * 3
            anchors.leftMargin: root.gap * 4
            anchors.rightMargin: root.gap * 4
            anchors.bottomMargin: root.gap * 4
            placementMode: ExpoLayout.Rows

            Repeater {
                model: KWinComponents.WindowFilterModel {
                    activity: KWinComponents.Workspace.currentActivity
                    desktop: root.currentDesktop
                    screenName: root.targetScreen.name
                    windowModel: allWindows
                    minimizedWindows: true
                    windowType: KWinComponents.WindowFilterModel.Normal | KWinComponents.WindowFilterModel.Dialog
                }
                WindowCell {
                    required property QtObject window
                    cellWindow: window
                    layout: heap
                    screen: root.targetScreen
                    onActivated: {
                        KWinComponents.Workspace.activeWindow = window
                        effect.deactivate()
                    }
                }
            }
        }
    }
}
