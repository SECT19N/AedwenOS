// The AedwenOS OSD pill itself (AedwenOS Desktop design, "OSD"), with the
// same properties as Plasma's OsdItem so anything importing it keeps working:
// Osd.qml (plasmashell's OSD window) and the lock screen's LockOsd.qml
// (look-and-feel .../lockscreen/LockOsd.qml, and Plasma's stock one).
//
// Progress (volume, brightness...): a 60 x 232 vertical pill. A secondary-
// container track fills from the bottom in primary, never shorter than a
// circle; the symbol sits in the fill, the value underneath.
// Text only (mute, power profile, keyboard layout...): a horizontal pill.
import QtQuick
import QtQuick.Effects
import org.kde.kirigami as Kirigami
import org.aedwen.ui

Item {
    id: root

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

    width: showingProgress ? 60 : row.implicitWidth + 2 * 18
    height: showingProgress ? 232 : 56

    Rectangle {
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

    // --- progress: vertical track ---------------------------------------
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
                visible: root.symbol === "" && root.icon !== ""
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
            color: root.value > 100 ? Theme.err : Theme.fg
        }
    }

    // --- text only: horizontal pill -------------------------------------
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
