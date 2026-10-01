// A Material Symbols Rounded icon by name, e.g. Sym { name: "wifi" }.
// The font's ligatures turn the name into the glyph, so any symbol from
// fonts.google.com/icons works without a codepoint table.
import QtQuick

Text {
    property string name
    property real fill: 0          // 0 outlined .. 1 filled
    property int weight: 400       // 400..600
    property int size: 20

    text: name
    width: size
    height: size
    font.family: Theme.symbols
    font.pixelSize: size
    font.variableAxes: ({ "FILL": fill, "wght": weight })
    color: Theme.fg
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
    renderType: Text.QtRendering
}
