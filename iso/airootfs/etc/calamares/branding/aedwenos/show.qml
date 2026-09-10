import QtQuick 2.0
import calamares.slideshow 1.0

Presentation {
    id: presentation

    Slide {
        Text {
            anchors.centerIn: parent
            text: "Installing AedwenOS…"
            font.pixelSize: 22
            color: "#1793d1"
        }
    }

    function onActivate() {}
    function onLeave() {}
}
