// Text in the shell font. role: "body" (14), "label" (12.5), "title" (15
// semibold), "display" (30), "caption" (12, variant colour).
import QtQuick

Text {
    property string role: "body"
    readonly property var _sizes: ({ body: 14, label: 13, title: 15, display: 30, caption: 12, headline: 22 })

    font.family: Theme.font
    font.pixelSize: _sizes[role] || 14
    font.weight: role === "title" || role === "display" || role === "headline" ? Font.DemiBold : Font.Normal
    font.features: role === "display" ? { "tnum": 1 } : {}
    color: role === "caption" ? Theme.fgVariant : Theme.fg
    elide: Text.ElideRight
    verticalAlignment: Text.AlignVCenter
}
