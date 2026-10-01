// Output volume of the default device; the symbol mutes/unmutes.
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.private.volume
import org.aedwen.ui

RowLayout {
    id: row
    readonly property var sink: PreferredDevice.sink
    readonly property bool available: sink !== null && sink !== undefined
    readonly property int percent: available ? Math.round(sink.volume / PulseAudio.NormalVolume * 100) : 0
    readonly property string symbol: !available || sink.muted || percent === 0 ? "volume_off"
                                   : percent < 40 ? "volume_down" : "volume_up"
    function step(delta) {
        if (!available) return
        const v = Math.max(0, Math.min(100, percent + delta))
        sink.muted = false
        sink.volume = Math.round(v / 100 * PulseAudio.NormalVolume)
    }
    spacing: 12
    IconButton {
        icon: row.symbol
        size: 36
        onClicked: if (row.available) row.sink.muted = !row.sink.muted
    }
    Slider {
        Layout.fillWidth: true
        to: 100
        value: row.percent
        onMoved: v => { if (row.available) { row.sink.muted = false; row.sink.volume = Math.round(v / 100 * PulseAudio.NormalVolume) } }
    }
}
