// Battery symbol (+ percentage) for laptops; hidden without a battery.
import QtQuick
import org.kde.plasma.private.battery
import org.aedwen.ui

Row {
    id: row
    property color color: Theme.fg
    property bool showPercent: true
    BatteryControlModel { id: battery }
    readonly property bool shown: battery.hasInternalBatteries
    readonly property int percent: battery.percent
    readonly property bool charging: battery.pluggedIn && battery.state === BatteryControlModel.Charging
    readonly property string summary: {
        if (!shown) return ""
        const ms = battery.smoothedRemainingMsec
        let s = percent + "%"
        if (ms > 0) {
            const h = Math.floor(ms / 3600000), m = Math.round((ms % 3600000) / 60000)
            s += " · " + (charging ? i18n("%1 h %2 min until full", h, m) : i18n("%1 h %2 min left", h, m))
        } else if (battery.pluggedIn) {
            s += " · " + (charging ? i18n("Charging") : i18n("Plugged in"))
        }
        return s
    }
    spacing: 3
    Sym {
        anchors.verticalCenter: parent.verticalCenter
        name: row.charging ? "battery_charging_full"
            : row.percent >= 95 ? "battery_full"
            : "battery_" + Math.max(0, Math.min(6, Math.round(row.percent / 100 * 6))) + "_bar"
        fill: 1
        size: 18
        color: row.percent < 10 && !row.charging ? Theme.err : row.color
    }
    Label {
        visible: row.showPercent
        anchors.verticalCenter: parent.verticalCenter
        text: row.percent + "%"
        role: "caption"
        color: row.color
    }
}
