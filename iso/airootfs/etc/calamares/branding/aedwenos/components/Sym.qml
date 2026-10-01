// A Material Symbols Rounded glyph, by name (see Theme.icons).
import QtQuick
import ".."

Text {
    property string name
    property real fill: 0
    property int size: 20

    text: Theme.icon(name)
    font.family: Theme.symbols
    font.pixelSize: size
    font.variableAxes: ({ "FILL": fill, "opsz": Math.max(20, Math.min(48, size)) })
    color: Theme.fg
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
    renderType: Text.QtRendering
}
