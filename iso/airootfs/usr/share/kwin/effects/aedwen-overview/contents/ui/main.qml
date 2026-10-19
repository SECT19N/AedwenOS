// AedwenOS Overview, replacing KWin's stock Overview. A QML-only scene
// effect (like KWin's Cube): one ScreenView per output, opened by the
// top-left hot corner (kwinrc [Effect-aedwen-overview] BorderActivate=7),
// Meta+W, or Shell.overview() from the shell.
//
// Look follows the AedwenOS Desktop design: a blurred, acrylic-tinted
// wallpaper; a strip of desktop cards along the top (the current one ringed
// in the accent, like a focused window, and a + card that adds a desktop);
// this desktop's windows laid out below with the design's 8 px rhythm.
import QtQuick
import org.kde.kwin as KWinComponents
import org.aedwen.ui

KWinComponents.SceneEffect {
    id: effect

    property bool activated: false
    readonly property int animationDuration: Theme.durMed

    delegate: Component { ScreenView {} }

    Instantiator {
        model: effect.configuration.BorderActivate
        KWinComponents.ScreenEdgeHandler {
            mode: KWinComponents.ScreenEdgeHandler.Pointer
            edge: modelData
            onActivated: effect.toggle()
        }
    }
    Instantiator {
        model: effect.configuration.TouchBorderActivate
        KWinComponents.ScreenEdgeHandler {
            mode: KWinComponents.ScreenEdgeHandler.Touch
            edge: modelData
            onActivated: effect.toggle()
        }
    }

    KWinComponents.ShortcutHandler {
        name: "AedwenOverview"
        text: i18n("Toggle Overview")
        sequence: "Meta+W"
        onActivated: effect.toggle()
    }

    Timer {
        id: deactivateTimer
        interval: effect.animationDuration
        onTriggered: effect.visible = false
    }

    function toggle() {
        if (activated)
            deactivate()
        else
            activate()
    }
    function activate() {
        if (activated || deactivateTimer.running)
            return
        visible = true
        activated = true
    }
    function deactivate() {
        if (!activated)
            return
        activated = false
        deactivateTimer.start()
    }
}
