// One action on the logout screen (Sleep, Restart, Shut down, ...): a 56px
// tonal icon container with the label under it. Hover / keyboard focus
// morph it from a circle to a rounded square (M3 Expressive); the
// screen's default action is filled primary.
//
// Same interface as Breeze's LogoutButton (Logout.qml is Plasma's logic):
// icon.name, text (with & mnemonics), clicked(), focus and KeyNavigation.
// Based on plasma-workspace's Breeze look-and-feel, GPL-2.0-or-later.
import QtQuick
import QtQuick.Layouts
import QtQuick.Templates as T
import org.aedwen.ui
import "timer.js" as AutoTriggerTimer

T.AbstractButton {
    id: button
    // the screen's default action (set in Logout.qml): filled primary
    property bool primary: false

    // Freedesktop icon names Logout.qml asks for -> Material Symbols
    readonly property var symbols: ({
        "system-suspend": "bedtime",
        "system-suspend-hibernate": "mode_standby",
        "system-reboot": "restart_alt",
        "system-reboot-update": "system_update_alt",
        "system-shutdown": "power_settings_new",
        "system-shutdown-update": "system_update_alt",
        "system-log-out": "logout",
        "dialog-cancel": "close",
    })
    readonly property bool lit: hovered || activeFocus || down

    Layout.alignment: Qt.AlignTop
    implicitWidth: 104
    implicitHeight: col.implicitHeight
    focusPolicy: Qt.StrongFocus
    Keys.onPressed: AutoTriggerTimer.cancelAutoTrigger()
    Keys.onReturnPressed: clicked()
    Keys.onEnterPressed: clicked()

    contentItem: Column {
        id: col
        spacing: 12
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 64
            height: 64
            radius: button.lit ? Theme.rCard : height / 2
            color: button.primary ? Theme.primary : Theme.secC
            scale: button.down ? 0.94 : 1
            Behavior on radius { NumberAnimation { duration: Theme.dur; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.spring } }
            Behavior on color { ColorAnimation { duration: Theme.durShort } }
            Behavior on scale { NumberAnimation { duration: Theme.durShort } }
            // keyboard focus ring (design: 3px primary, 2px offset)
            Rectangle {
                anchors.fill: parent
                anchors.margins: -5
                radius: parent.radius + 5
                color: "transparent"
                border.width: 3
                border.color: Theme.primary
                visible: button.visualFocus
            }
            Sym {
                anchors.centerIn: parent
                name: button.symbols[button.icon.name] || "power_settings_new"
                size: 28
                fill: 1
                color: button.primary ? Theme.primaryFg : Theme.secCFg
            }
        }
        Label {
            width: button.implicitWidth
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            elide: Text.ElideNone
            // drop the & mnemonic markers
            text: button.text.replace(/&(?!&)/g, "")
            role: "label"
            font.weight: Font.DemiBold
            opacity: button.lit || button.primary ? 1 : 0.8
        }
    }
}
