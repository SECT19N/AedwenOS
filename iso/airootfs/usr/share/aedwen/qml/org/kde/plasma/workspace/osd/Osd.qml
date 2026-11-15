// AedwenOS on-screen display window (AedwenOS Desktop design, "OSD"): the
// OsdItem pill on the right edge, 20 px in, vertically centred, sliding in
// 32 px from the right as it fades.
//
// plasmashell's interface to this object (plasma-workspace shell/osd.cpp) is
// properties only: it sets osdValue, osdMaxValue, osdAdditionalText, icon,
// showingProgress, then visible = true, and visible = false after `timeout`
// ms. The root is a plain QtObject so `visible` can run the exit animation
// before the window really hides. No `animateOpacity` property on purpose:
// that would make plasmashell drive the fade itself.
import QtQuick
import org.kde.layershell as LayerShell
import org.aedwen.ui

QtObject {
    id: root

    property bool visible: false
    property alias timeout: pill.timeout
    property alias osdValue: pill.osdValue
    property alias osdMaxValue: pill.osdMaxValue
    property alias osdAdditionalText: pill.osdAdditionalText
    property alias icon: pill.icon
    property alias showingProgress: pill.showingProgress

    onVisibleChanged: {
        if (visible) {
            hideAnim.stop()
            if (!win.visible) {
                pill.opacity = 0
                pill.slide = 32
                win.visible = true
            }
            showAnim.restart()
        } else {
            showAnim.stop()
            hideAnim.restart()
        }
    }

    property ParallelAnimation showAnim: ParallelAnimation {
        NumberAnimation { target: pill; property: "opacity"; to: 1; duration: Theme.animate ? 200 : 0 }
        NumberAnimation {
            target: pill; property: "slide"; to: 0; duration: Theme.animate ? 320 : 0
            easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.standard
        }
    }
    property SequentialAnimation hideAnim: SequentialAnimation {
        ParallelAnimation {
            NumberAnimation { target: pill; property: "opacity"; to: 0; duration: Theme.animate ? 200 : 0 }
            NumberAnimation {
                target: pill; property: "slide"; to: 32; duration: Theme.animate ? 320 : 0
                easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.standard
            }
        }
        ScriptAction { script: win.visible = false }
    }

    property Window win: Window {
        id: win

        // around the pill: room for the shadow and the 32 px slide on the
        // left, the design's 20 px to the screen edge on the right
        readonly property int pad: 40

        color: "transparent"
        flags: Qt.FramelessWindowHint | Qt.WindowDoesNotAcceptFocus | Qt.WindowTransparentForInput
        width: pill.width + pad + 20
        height: pill.height + 2 * pad
        // X11 fallback only; on Wayland the layer-shell anchors place it
        x: screen ? screen.virtualX + screen.width - width : 0
        y: screen ? screen.virtualY + (screen.height - height) / 2 : 0

        LayerShell.Window.scope: "aedwen-osd"
        LayerShell.Window.layer: LayerShell.Window.LayerOverlay
        LayerShell.Window.anchors: LayerShell.Window.AnchorRight
        LayerShell.Window.keyboardInteractivity: LayerShell.Window.KeyboardInteractivityNone
        LayerShell.Window.exclusionZone: -1
        LayerShell.Window.wantsToBeOnActiveScreen: true

        OsdItem {
            id: pill
            property real slide: 0
            x: win.pad + slide
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
