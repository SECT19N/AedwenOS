// Any application's real icon inside a rounded tile tinted with the icon's
// own dominant colour (design: dock and launcher tiles). Works for every
// installed app -- nothing is hard-coded per app.
//   neutral: true  -> plain surface tile (launcher/trash buttons, symbols)
//   symbol         -> draw a Material Symbol instead of an app icon
import QtQuick
import org.kde.kirigami as Kirigami

Rectangle {
    id: root
    property var source           // icon name, path, url or QIcon
    property string symbol
    property bool neutral: symbol !== ""
    property bool hovered: false
    property int size: 40
    property real iconScale: 0.7

    // The icon's accent hue at a fixed tone (design: oklch(.72 .12 h)), so
    // every app's tile has the same weight whatever its icon looks like.
    readonly property color _accent: colors.highlight
    readonly property bool _ok: !neutral && colors.palette !== undefined && colors.palette.length > 0
                               && _accent.hsvSaturation > 0.12
    readonly property color tint: Qt.hsla(_accent.hslHue,
                                          Math.max(0.35, Math.min(0.65, _accent.hslSaturation)),
                                          Theme.dark ? 0.68 : 0.52, 1)

    implicitWidth: size
    implicitHeight: size
    radius: Math.round(size * 0.28)
    color: !_ok ? Theme.alpha(Theme.scHighest, Theme.dark ? 0.9 : 0.7)
         : Theme.alpha(tint, hovered ? (Theme.dark ? 0.32 : 0.34) : (Theme.dark ? 0.22 : 0.24))
    border.width: 1
    border.color: !_ok ? Theme.outlineV
                : Theme.alpha(Theme.mix(tint, Theme.dark ? "white" : "black", 0.2), Theme.dark ? 0.3 : 0.24)
    Behavior on color { ColorAnimation { duration: Theme.durShort } }

    Kirigami.ImageColors {
        id: colors
        source: root.neutral ? "" : root.source
    }
    Kirigami.Icon {
        visible: root.symbol === ""
        anchors.centerIn: parent
        width: Math.round(root.size * root.iconScale)
        height: width
        source: root.source
        animated: false
    }
    Sym {
        visible: root.symbol !== ""
        anchors.centerIn: parent
        name: root.symbol
        size: Math.round(root.size * 0.55)
        fill: 1
        weight: 500
    }
}
