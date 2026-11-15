// AedwenOS on-screen display, from the AedwenOS Desktop design ("OSD"): a
// 60 x 232 vertical pill on the right edge, vertically centred. A secondary-
// container track fills from the bottom in primary (never shorter than a
// circle), the symbol sits in the fill, the value underneath. It slides in
// 32 px from the right and fades. Text-only OSDs (mute, power profile,
// keyboard layout...) use a horizontal pill with the same surface.
//
// plasmashell's interface to this object (plasma-workspace shell/osd.cpp) is
// properties only: it sets osdValue, osdMaxValue, osdAdditionalText, icon,
// showingProgress, then visible = true, and visible = false after `timeout`
// ms. The root is a plain QtObject so `visible` can run the exit animation
// before the window really hides. No `animateOpacity` property on purpose:
// that would make plasmashell drive the fade itself.
import QtQuick
import QtQuick.Effects
import org.kde.kirigami as Kirigami
import org.kde.layershell as LayerShell
import org.aedwen.ui

QtObject {
    id: root

    property bool visible: false
    property int timeout: 1800
    property var osdValue
    property int osdMaxValue: 100
    property string osdAdditionalText: ""
    property string icon
    property bool showingProgress: false

    readonly property real value: Number(osdValue) || 0
    readonly property real fraction: osdMaxValue > 0 ? Math.max(0, Math.min(1, value / osdMaxValue)) : 0
    readonly property string text: (showingProgress ? osdAdditionalText : String(osdValue ?? "")) || ""

    // freedesktop icon name -> Material Symbol; "" falls back to the icon theme
    function symbolFor(name, v) {
        const n = (name || "").toLowerCase()
        if (n.startsWith("audio-volume")) {
            if (n.includes("muted") || (showingProgress && v <= 0)) return "volume_off"
            return n.includes("low") || (showingProgress && v < 40) ? "volume_down" : "volume_up"
        }
        if (n.startsWith("microphone") || n.includes("audio-input"))
            return n.includes("muted") ? "mic_off" : "mic"
        if (n.includes("keyboard-brightness")) return "keyboard"
        if (n.includes("brightness") || n.includes("display")) return "light_mode"
        if (n.includes("touchpad")) return n.includes("off") ? "touchpad_mouse_off" : "touchpad_mouse"
        if (n.includes("powersave")) return "eco"
        if (n.includes("performance")) return "speed"
        if (n.includes("balanced")) return "balance"
        if (n.includes("battery")) return "battery_5_bar"
        if (n.includes("keyboard") || n.includes("input-keyboard")) return "keyboard"
        if (n.includes("media-playback-start")) return "play_arrow"
        if (n.includes("media-playback-pause")) return "pause"
        return ""
    }
    readonly property string symbol: symbolFor(icon, value)

    onVisibleChanged: {
        if (visible) {
            hideAnim.stop()
            if (!win.visible) {
                content.opacity = 0
                content.slide = 32
                win.visible = true
            }
            showAnim.restart()
        } else {
            showAnim.stop()
            hideAnim.restart()
        }
    }

    property ParallelAnimation showAnim: ParallelAnimation {
        NumberAnimation { target: content; property: "opacity"; to: 1; duration: Theme.animate ? 200 : 0 }
        NumberAnimation {
            target: content; property: "slide"; to: 0; duration: Theme.animate ? 320 : 0
            easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.standard
        }
    }
    property SequentialAnimation hideAnim: SequentialAnimation {
        ParallelAnimation {
            NumberAnimation { target: content; property: "opacity"; to: 0; duration: Theme.animate ? 200 : 0 }
            NumberAnimation {
                target: content; property: "slide"; to: 32; duration: Theme.animate ? 320 : 0
                easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.standard
            }
        }
        ScriptAction { script: win.visible = false }
    }

    property Window win: Window {
        id: win

        // margins around the pill: 20 px to the screen edge (design), plus
        // room for the shadow and the 32 px slide
        readonly property int pad: 40

        color: "transparent"
        flags: Qt.FramelessWindowHint | Qt.WindowDoesNotAcceptFocus | Qt.WindowTransparentForInput
        width: content.width + pad + 20
        height: content.height + 2 * pad
        // X11 fallback only; on Wayland the layer-shell anchors place it
        x: screen ? screen.virtualX + screen.width - width : 0
        y: screen ? screen.virtualY + (screen.height - height) / 2 : 0

        LayerShell.Window.scope: "aedwen-osd"
        LayerShell.Window.layer: LayerShell.Window.LayerOverlay
        LayerShell.Window.anchors: LayerShell.Window.AnchorRight
        LayerShell.Window.keyboardInteractivity: LayerShell.Window.KeyboardInteractivityNone
        LayerShell.Window.exclusionZone: -1
        LayerShell.Window.wantsToBeOnActiveScreen: true

        Item {
            id: content
            property real slide: 0
            width: root.showingProgress ? 60 : row.implicitWidth + 2 * 18
            height: root.showingProgress ? 232 : 56
            x: win.pad + slide
            anchors.verticalCenter: parent.verticalCenter

            Rectangle {
                id: surface
                anchors.fill: parent
                radius: root.showingProgress ? 30 : height / 2
                color: Theme.scHigh
                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowColor: Qt.rgba(0, 0, 0, 0.3)
                    shadowBlur: 0.8
                    shadowVerticalOffset: 12
                    autoPaddingEnabled: true
                }
            }

            // --- progress: vertical track ---------------------------------
            Column {
                visible: root.showingProgress
                anchors.fill: parent
                anchors.margins: 8
                spacing: 8

                Rectangle {
                    id: track
                    width: 44
                    height: parent.height - parent.spacing - valueLabel.height
                    radius: 22
                    color: Theme.secC
                    clip: true

                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        height: Math.max(44, track.height * root.fraction)
                        radius: 22
                        color: Theme.primary
                        Behavior on height {
                            NumberAnimation {
                                duration: Theme.animate ? 160 : 0
                                easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.standard
                            }
                        }
                    }

                    Sym {
                        visible: root.symbol !== ""
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 11
                        name: root.symbol
                        size: 22
                        fill: 1
                        color: Theme.primaryFg
                    }
                    Kirigami.Icon {
                        visible: root.symbol === ""
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 11
                        width: 22
                        height: 22
                        source: root.icon
                        isMask: true
                        color: Theme.primaryFg
                    }
                }

                Text {
                    id: valueLabel
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Math.round(root.value)
                    font.family: Theme.font
                    font.pixelSize: 13
                    font.weight: Font.Bold
                    font.features: { "tnum": 1 }
                    // over 100 % (amplified volume) shows in the warning colour
                    color: root.value > root.osdMaxValue || (root.osdMaxValue > 100 && root.value > 100)
                           ? Theme.err : Theme.fg
                }
            }

            // --- text only: horizontal pill --------------------------------
            Row {
                id: row
                visible: !root.showingProgress
                anchors.centerIn: parent
                spacing: 12

                Sym {
                    visible: root.symbol !== ""
                    anchors.verticalCenter: parent.verticalCenter
                    name: root.symbol
                    size: 22
                    fill: 1
                }
                Kirigami.Icon {
                    visible: root.symbol === "" && root.icon !== ""
                    anchors.verticalCenter: parent.verticalCenter
                    width: 22
                    height: 22
                    source: root.icon
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.text
                    textFormat: Text.PlainText
                    font.family: Theme.font
                    font.pixelSize: 14
                    font.weight: Font.Medium
                    color: Theme.fg
                }
            }
        }
    }
}
