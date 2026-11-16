// Screen brightness, one slider per display that supports it.
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.private.brightnesscontrolplugin
import org.aedwen.ui

ColumnLayout {
    id: col
    readonly property bool available: control.isBrightnessAvailable
    spacing: 12
    ScreenBrightnessControl { id: control; isSilent: true }
    Repeater {
        model: control.displays
        RowLayout {
            required property string displayName
            required property string label
            required property int brightness
            required property int maxBrightness
            Layout.fillWidth: true
            spacing: 12
            Sym {
                name: "light_mode"
                size: 22
                color: Theme.fgVariant
            }
            Slider {
                Layout.fillWidth: true
                to: maxBrightness
                stepSize: Math.max(1, maxBrightness / 100)
                value: brightness
                onMoved: v => control.setBrightness(displayName, v)
            }
        }
    }
}
