// Login splash (KSplash), shown while Plasma starts after you log in.
//
// It continues the Plymouth boot splash (System Surfaces design §07, "Boot
// splash: the eagle in the seed's primary colour, the loading shape morphs,
// no text"): same dark ground, same eagle / gap / loader proportions, and
// the same M3E morphing loader (org.aedwen.ui MorphShape draws the shapes
// scripts/generate-plymouth-assets.py renders for Plymouth). So boot ->
// login -> desktop reads as one sequence instead of switching to KDE's.
//
// Colours are Plymouth's, not the colour scheme's: Plymouth runs before any
// user setting exists, and the splash must match it exactly to look
// seamless (light theme included, like the design's disk prompt).
//
// KSplash API: `stage` goes 1..6 as Plasma starts; fade in at 2, out at 5.
// The light global theme points at this package's splash too.
import QtQuick
import QtQuick.Window
import org.aedwen.ui

Rectangle {
    id: root
    color: "#0d0b13"          // Plymouth background (dark surface)

    property int stage

    readonly property color accent: "#cdacff"   // Plymouth eagle / loader (dark primary)
    // Plymouth draws in physical pixels: logo 256, gap 40, loader 80.
    readonly property real px: 1 / Screen.devicePixelRatio
    readonly property real logoSize: 256 * px
    readonly property real gap: 40 * px
    readonly property real loaderBox: 80 * px

    onStageChanged: {
        if (stage === 2)
            fadeIn.start()
        else if (stage === 5)
            fadeOut.start()
    }

    Item {
        id: content
        anchors.fill: parent
        opacity: 0

        Column {
            anchors.centerIn: parent
            spacing: root.gap

            Item {
                anchors.horizontalCenter: parent.horizontalCenter
                width: root.logoSize
                height: root.logoSize
                // logo.png pads the eagle inside its 256 px; match its size
                // and position (measured against the Plymouth frame)
                EagleMark {
                    width: root.logoSize * 0.945
                    height: width
                    x: (parent.width - width) / 2 + 5 * root.px
                    y: (parent.height - height) / 2 + 1 * root.px
                    color: root.accent
                }
            }
            Item {
                anchors.horizontalCenter: parent.horizontalCenter
                width: root.loaderBox
                height: root.loaderBox
                MorphShape {
                    anchors.centerIn: parent
                    width: root.loaderBox - 4 * root.px
                    height: width
                    color: root.accent
                    running: root.stage < 6
                }
            }
        }
    }

    // Plymouth hands over to the same picture, so appear quickly; leave
    // gently into the desktop.
    OpacityAnimator { id: fadeIn; target: content; from: 0; to: 1; duration: 250; easing.type: Easing.OutQuad }
    OpacityAnimator { id: fadeOut; target: content; from: 1; to: 0; duration: 400; easing.type: Easing.InOutQuad }
}
