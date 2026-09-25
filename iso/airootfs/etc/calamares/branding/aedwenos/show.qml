import QtQuick 2.0
import calamares.slideshow 1.0

Presentation {
    id: presentation

    Slide {
        Rectangle {
            anchors.fill: parent
            color: "#0d0b13"
        }
        Text {
            anchors.centerIn: parent
            text: "Installing AedwenOS…"
            font.pixelSize: 22
            font.bold: true
            color: "#cdacff"
        }
    }

    function onActivate() {}
    function onLeave() {}
}
