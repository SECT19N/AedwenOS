// Install slideshow (design: installer "Install" step). A coloured card per
// slide with a big icon in a shape that springs to a new form on each
// slide, plus dot indicators. Calamares' own progress bar sits below.
// Slideshow API 2: activatedInCalamares / onActivate() / onLeave().
import QtQuick
import QtQuick.Layouts
import "."

Rectangle {
    id: root
    color: Theme.surface

    property bool activatedInCalamares: false
    property int current: 0

    // [icon, title, text, background, foreground, corner radii as fractions TL TR BR BL]
    readonly property var slides: [
        ["palette", qsTr("One colour, everywhere"),
         qsTr("Pick a seed colour. The desktop, apps, icons and even the cursor follow it."),
         Theme.pc, Theme.pcFg, [0.5, 0.5, 0.5, 0.5]],
        ["view_quilt", qsTr("Snap and tile"),
         qsTr("Drag a window to an edge or corner to snap it, or use Meta and the arrow keys."),
         Theme.secC, Theme.secCFg, [0.3, 0.3, 0.3, 0.3]],
        ["search", qsTr("Find anything"),
         qsTr("Press Alt Space to search apps, files, settings and quick maths."),
         Theme.terC, Theme.terCFg, [0.5, 0.5, 0.5, 0.22]],
        ["storefront", qsTr("Apps from Octopi"),
         qsTr("The Arch repositories and the AUR in one app, with updates in the background."),
         Theme.pc, Theme.pcFg, [0.5, 0.22, 0.5, 0.22]],
    ]
    readonly property var slide: slides[current]

    function onActivate() { current = 0 }
    function onLeave() {}

    Timer {
        interval: 6000
        repeat: true
        running: root.activatedInCalamares
        onTriggered: root.current = (root.current + 1) % root.slides.length
    }

    Rectangle {
        id: card
        anchors.fill: parent
        anchors.margins: 28
        anchors.leftMargin: 32
        anchors.rightMargin: 32
        radius: Theme.rCard
        color: root.slide[3]
        Behavior on color { ColorAnimation { duration: 500 } }

        RowLayout {
            anchors.fill: parent
            anchors.margins: 32
            anchors.bottomMargin: 40
            spacing: 24

            ColumnLayout {
                Layout.fillWidth: true
                Layout.preferredWidth: 11
                spacing: 12
                Text {
                    text: "0" + (root.current + 1) + " / 0" + root.slides.length
                    color: root.slide[4]
                    opacity: 0.8
                    font.family: Theme.mono
                    font.pixelSize: 11
                    font.letterSpacing: 1.3
                }
                Text {
                    Layout.fillWidth: true
                    text: root.slide[1]
                    wrapMode: Text.WordWrap
                    color: root.slide[4]
                    font.family: Theme.font
                    font.pixelSize: 30
                    font.weight: Font.Bold
                }
                Text {
                    Layout.fillWidth: true
                    text: root.slide[2]
                    wrapMode: Text.WordWrap
                    lineHeight: 1.15
                    color: root.slide[4]
                    opacity: 0.9
                    font.family: Theme.font
                    font.pixelSize: 15
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.preferredWidth: 10
                Layout.fillHeight: true
                Rectangle {
                    id: shape
                    readonly property real s: Math.min(150, parent.height)
                    readonly property var r: root.slide[5]
                    anchors.centerIn: parent
                    width: s
                    height: s
                    color: root.slide[4]
                    topLeftRadius: r[0] * s
                    topRightRadius: r[1] * s
                    bottomRightRadius: r[2] * s
                    bottomLeftRadius: r[3] * s
                    Behavior on topLeftRadius { NumberAnimation { duration: 700; easing.type: Easing.OutBack } }
                    Behavior on topRightRadius { NumberAnimation { duration: 700; easing.type: Easing.OutBack } }
                    Behavior on bottomRightRadius { NumberAnimation { duration: 700; easing.type: Easing.OutBack } }
                    Behavior on bottomLeftRadius { NumberAnimation { duration: 700; easing.type: Easing.OutBack } }
                    Behavior on color { ColorAnimation { duration: 500 } }
                    Sym {
                        anchors.centerIn: parent
                        name: root.slide[0]
                        fill: 1
                        size: 72
                        color: root.slide[3]
                    }
                }
            }
        }

        Row {
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            anchors.leftMargin: 32
            anchors.bottomMargin: 18
            spacing: 6
            Repeater {
                model: root.slides.length
                Rectangle {
                    width: index === root.current ? 22 : 6
                    height: 6
                    radius: 3
                    color: root.slide[4]
                    opacity: index === root.current ? 1 : 0.4
                    Behavior on width { NumberAnimation { duration: 300 } }
                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -6
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.current = index
                    }
                }
            }
        }
    }
}
