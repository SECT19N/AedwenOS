// Now playing (Desktop design: QUICK SETTINGS media card). Tertiary
// container card: 60 px album art, title / artist, a 4 px progress bar with
// position and length, and previous / play-pause / next. The play button is
// a circle while paused and morphs to a 14 px rounded square while playing
// (Expressive). Hidden when no MPRIS player is running.
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import org.kde.plasma.private.mpris as Mpris
import org.aedwen.ui

Rectangle {
    id: card
    Mpris.Mpris2Model { id: mpris }
    readonly property var player: mpris.currentPlayer
    readonly property bool available: player !== null && player !== undefined
    readonly property bool playing: available && player.playbackStatus === Mpris.PlaybackStatus.Playing
    readonly property real length: available ? player.length : 0      // µs
    readonly property real position: available ? player.position : 0  // µs

    function fmt(us) {
        const s = Math.max(0, Math.floor(us / 1000000))
        return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0")
    }

    implicitHeight: row.implicitHeight + 24
    radius: Theme.rCard
    color: Theme.terC

    // MPRIS only signals position on seeks; poll while visible and playing
    Timer {
        running: card.visible && card.playing
        interval: 1000
        repeat: true
        triggeredOnStart: true
        onTriggered: card.player.updatePosition()
    }

    RowLayout {
        id: row
        anchors.fill: parent
        anchors.margins: 12
        spacing: 14

        Rectangle {
            id: artBox
            Layout.preferredWidth: 60
            Layout.preferredHeight: 60
            radius: Theme.expressive ? 18 : 12
            color: Theme.alpha(Theme.terCFg, 0.14)
            Sym {
                anchors.centerIn: parent
                visible: art.status !== Image.Ready
                name: "album"
                size: 28
                fill: 1
                color: Theme.terCFg
            }
            Image {
                id: art
                anchors.fill: parent
                source: card.available ? card.player.artUrl : ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                visible: false
                sourceSize: Qt.size(120, 120)
            }
            // the art takes the box's rounded corners
            Rectangle {
                id: artMask
                anchors.fill: parent
                radius: artBox.radius
                visible: false
                layer.enabled: true
            }
            MultiEffect {
                anchors.fill: parent
                visible: art.status === Image.Ready
                source: art
                maskEnabled: true
                maskSource: artMask
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                Label {
                    Layout.fillWidth: true
                    text: card.available ? (card.player.track || card.player.identity) : ""
                    font.pixelSize: 14
                    font.weight: Font.Bold
                    color: Theme.terCFg
                }
                Label {
                    Layout.fillWidth: true
                    visible: text !== ""
                    text: card.available ? card.player.artist : ""
                    font.pixelSize: 12
                    color: Theme.terCFg
                    opacity: 0.85
                }
            }
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 4
                radius: 2
                color: Theme.alpha(Theme.terCFg, 0.22)
                Rectangle {
                    width: card.length > 0 ? parent.width * Math.min(1, card.position / card.length) : 0
                    height: parent.height
                    radius: 2
                    color: Theme.terCFg
                    Behavior on width { NumberAnimation { duration: Theme.animate ? 900 : 0 } }
                }
            }
            RowLayout {
                Layout.fillWidth: true
                visible: card.length > 0
                Text {
                    text: card.fmt(card.position)
                    font.family: Theme.mono
                    font.pixelSize: 11
                    color: Theme.terCFg
                    opacity: 0.85
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: card.fmt(card.length)
                    font.family: Theme.mono
                    font.pixelSize: 11
                    color: Theme.terCFg
                    opacity: 0.85
                }
            }
        }

        Row {
            spacing: 2
            Layout.alignment: Qt.AlignVCenter
            component SkipButton: Rectangle {
                id: skip
                property string icon
                property bool can: true
                signal clicked()
                anchors.verticalCenter: parent.verticalCenter
                width: 34
                height: 34
                radius: 17
                color: "transparent"
                opacity: can ? 1 : 0.38
                StateLayer { area: skipMouse; tint: Theme.terCFg }
                Sym { anchors.centerIn: parent; name: skip.icon; size: 22; fill: 1; color: Theme.terCFg }
                MouseArea {
                    id: skipMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: skip.can
                    cursorShape: Qt.PointingHandCursor
                    onClicked: skip.clicked()
                }
            }
            SkipButton {
                icon: "skip_previous"
                can: card.available && card.player.canGoPrevious
                onClicked: card.player.Previous()
            }
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 44
                height: 44
                radius: card.playing && Theme.expressive ? 14 : 22
                color: Theme.terCFg
                Behavior on radius { NumberAnimation { duration: Theme.dur; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.morphEasing } }
                StateLayer { area: playMouse; tint: Theme.terC }
                Sym { anchors.centerIn: parent; name: card.playing ? "pause" : "play_arrow"; size: 24; fill: 1; color: Theme.terC }
                MouseArea {
                    id: playMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: card.available && card.player.canControl
                    cursorShape: Qt.PointingHandCursor
                    onClicked: card.player.PlayPause()
                }
            }
            SkipButton {
                icon: "skip_next"
                can: card.available && card.player.canGoNext
                onClicked: card.player.Next()
            }
        }
    }
}
