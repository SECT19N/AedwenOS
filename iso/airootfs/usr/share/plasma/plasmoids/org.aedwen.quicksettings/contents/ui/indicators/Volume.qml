import QtQuick
import org.kde.plasma.private.volume
import org.aedwen.ui

Sym {
    readonly property var sink: PreferredDevice.sink
    readonly property bool shown: sink !== null && sink !== undefined
    readonly property int percent: shown ? Math.round(sink.volume / PulseAudio.NormalVolume * 100) : 0
    name: !shown || sink.muted || percent === 0 ? "volume_off" : percent < 40 ? "volume_down" : "volume_up"
    fill: 1
    size: 18
}
