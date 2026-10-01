// The AedwenOS eagle in one palette colour (the design masks
// assets/aedwen-eagle.png the same way). The tints are pre-rendered by
// scripts/generate-calamares-branding.py as eagle-<tint>.png.
import QtQuick

Image {
    property string tint: "primary"      // primary | primary-fg | pc-fg
    source: Qt.resolvedUrl("../eagle-" + tint + ".png")
    sourceSize.width: 256
    sourceSize.height: 256
    fillMode: Image.PreserveAspectFit
    smooth: true
    mipmap: true
}
