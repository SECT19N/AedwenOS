// Renders the install step's "toggle log" button icon for the AedwenOS
// Calamares branding: Material Symbols Rounded "terminal" in the palette's
// primary colour, from the branding's own subset font and generated Theme.qml
// (so re-run it after scripts/generate-calamares-branding.py changes the
// seed). Calamares (ExecutionViewStep) looks for a branding file named
// exactly "utilities-log-viewer" before falling back to the icon theme, and
// loads it with QPixmap, which detects PNG by content -- hence no extension.
//
// QImage picks the format from the suffix, so it writes a .png and the
// usage line renames it. From the repo root:
//     B=iso/airootfs/etc/calamares/branding/aedwenos
//     qml6 scripts/render-calamares-log-icon.qml && mv $B/utilities-log-viewer.png $B/utilities-log-viewer
import QtQuick
import "../iso/airootfs/etc/calamares/branding/aedwenos"

Window {
    width: 64
    height: 64
    color: "transparent"
    visible: true

    Sym {
        id: glyph
        anchors.centerIn: parent
        name: "terminal"
        size: 56
        color: Theme.primary
    }

    Timer {
        running: true
        interval: 500
        onTriggered: glyph.parent.grabToImage(result => {
            const out = Qt.resolvedUrl("../iso/airootfs/etc/calamares/branding/aedwenos/utilities-log-viewer.png")
            if (!result.saveToFile(out.toString().replace("file://", "")))
                console.error("could not write", out)
            Qt.quit()
        })
    }
}
