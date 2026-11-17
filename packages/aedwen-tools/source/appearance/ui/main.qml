// Appearance (System Surfaces design: Settings > Appearance). Two style
// cards (Material 3 / Expressive), the Colour group (from wallpaper, accent
// colour with a custom hue / hex panel, theme, contrast) and the Details
// group (cursors, icons, fonts, sounds). Everything applies at once; see
// appearance.h.
import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import org.kde.kcmutils as KCMUtils
import org.aedwen.ui

KCMUtils.SimpleKCM {
    id: root
    readonly property var kcm_: kcm

    // design's seg(): the chosen option is a pill in primary; the rest are
    // surface-container-highest with 10 px inner corners, 20 px outer ends
    component Segmented: Row {
        id: seg
        property var options: []     // [[value, label], ...]
        property string current
        signal picked(string value)
        spacing: 2
        height: 36
        Repeater {
            model: seg.options
            Rectangle {
                id: opt
                required property var modelData
                required property int index
                readonly property bool on: seg.current === modelData[0]
                readonly property bool first: index === 0
                readonly property bool last: index === seg.options.length - 1
                height: 36
                width: optLabel.implicitWidth + 28
                color: on ? Theme.primary : Theme.scHighest
                topLeftRadius: on ? 18 : first ? 20 : 10
                bottomLeftRadius: on ? 18 : first ? 20 : 10
                topRightRadius: on ? 18 : last ? 20 : 10
                bottomRightRadius: on ? 18 : last ? 20 : 10
                Behavior on color { ColorAnimation { duration: 200 } }
                StateLayer { area: optMouse; tint: opt.on ? Theme.primaryFg : Theme.fg }
                Label {
                    id: optLabel
                    anchors.centerIn: parent
                    text: opt.modelData[1]
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                    color: opt.on ? Theme.primaryFg : Theme.fg
                }
                MouseArea {
                    id: optMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: seg.picked(opt.modelData[0])
                }
            }
        }
    }

    // a row of the Colour / Details groups
    component GroupRow: Rectangle {
        id: grow
        property string title
        property string subtitle
        property bool first: false
        property bool last: false
        default property alias trailing: trail.data
        Layout.fillWidth: true
        topLeftRadius: first ? Theme.rCard : 4
        topRightRadius: first ? Theme.rCard : 4
        bottomLeftRadius: last ? Theme.rCard : 4
        bottomRightRadius: last ? Theme.rCard : 4
        implicitHeight: Math.max(60, rowLayout.implicitHeight + 28)
        color: Theme.scLow
        RowLayout {
            id: rowLayout
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            spacing: 14
            ColumnLayout {
                Layout.fillWidth: true
                Layout.minimumWidth: 160
                spacing: 2
                Label { text: grow.title; font.pixelSize: 14; Layout.fillWidth: true }
                Label { text: grow.subtitle; font.pixelSize: 13; color: Theme.fgVariant; visible: text !== ""; Layout.fillWidth: true; wrapMode: Text.Wrap; elide: Text.ElideNone }
            }
            Row { id: trail; spacing: 8; Layout.alignment: Qt.AlignVCenter }
        }
    }

    component Ring: Rectangle {
        // the design's selection ring: 3 px gap, 2 px primary
        property bool on: false
        anchors.centerIn: parent
        width: parent.width + 10
        height: parent.height + 10
        radius: width / 2
        color: "transparent"
        border.width: 2
        border.color: Theme.primary
        visible: on
    }

    ColumnLayout {
        width: Math.min(parent.width, 760)
        spacing: 22

        // --- style -----------------------------------------------------------
        GridLayout {
            Layout.fillWidth: true
            columns: root.width > 520 ? 2 : 1
            columnSpacing: 12
            rowSpacing: 12
            Repeater {
                model: [
                    ["baseline", i18n("Material 3"), i18n("Calm, consistent corners · default")],
                    ["expressive", i18n("Expressive"), i18n("Bolder colour, shape morphs, springy motion")]
                ]
                Rectangle {
                    id: card
                    required property var modelData
                    readonly property bool on: kcm.variant === modelData[0]
                    readonly property bool ex: modelData[0] === "expressive"
                    Layout.fillWidth: true
                    implicitHeight: col.implicitHeight + 20
                    radius: Theme.rCard
                    color: Theme.scLow
                    border.width: 2
                    border.color: on ? Theme.primary : "transparent"
                    StateLayer { area: cardMouse }
                    ColumnLayout {
                        id: col
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 10
                        // 16:9 preview with the variant's shapes
                        Rectangle {
                            id: pv
                            Layout.fillWidth: true
                            Layout.preferredHeight: width * 9 / 16
                            radius: Theme.rInner
                            color: Theme.scHighest
                            clip: true
                            Rectangle { width: parent.width; height: parent.height * 0.1; color: Theme.sc }
                            Rectangle {
                                x: parent.width * 0.12; y: parent.height * 0.2
                                width: parent.width * 0.52; height: parent.height * 0.52
                                radius: card.ex ? 8 : 6
                                color: Theme.surface
                                border.width: 1.5
                                border.color: Theme.primary
                            }
                            Rectangle {
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.bottom: parent.bottom
                                anchors.bottomMargin: parent.height * 0.06
                                width: dockRow.implicitWidth + 8
                                height: 20
                                radius: card.ex ? 10 : 8
                                color: Theme.sc
                                Row {
                                    id: dockRow
                                    anchors.centerIn: parent
                                    spacing: 4
                                    Rectangle { width: 12; height: 12; radius: card.ex ? 4 : 6; color: Theme.pc }
                                    Rectangle { width: 12; height: 12; radius: 6; color: Theme.primary }
                                    Rectangle { width: 12; height: 12; radius: card.ex ? 4 : 6; color: Theme.secC }
                                    Rectangle { width: 12; height: 12; radius: card.ex ? 4 : 6; color: Theme.secC }
                                }
                            }
                            Rectangle {
                                x: parent.width * 0.7; y: parent.height * 0.18
                                width: parent.width * 0.24; height: parent.height * 0.42
                                radius: card.ex ? 12 : 9
                                color: Theme.scHigh
                                Grid {
                                    anchors.fill: parent
                                    anchors.margins: 5
                                    columns: 2
                                    spacing: 3
                                    Repeater {
                                        model: 4
                                        Rectangle {
                                            required property int index
                                            width: (parent.width - 3) / 2
                                            height: 10
                                            radius: index === 0 || index === 3 ? (card.ex ? 5 : 3) : 5
                                            color: index === 0 || index === 3 ? Theme.primary : Theme.scHighest
                                        }
                                    }
                                }
                            }
                        }
                        RowLayout {
                            Layout.leftMargin: 4
                            spacing: 10
                            Rectangle {
                                width: 18; height: 18; radius: 9
                                color: "transparent"
                                border.width: 2
                                border.color: card.on ? Theme.primary : Theme.fgVariant
                                Rectangle { anchors.centerIn: parent; width: 8; height: 8; radius: 4; color: Theme.primary; visible: card.on }
                            }
                            ColumnLayout {
                                spacing: 0
                                Label { text: card.modelData[1]; font.pixelSize: 14; font.weight: Font.DemiBold }
                                Label { text: card.modelData[2]; font.pixelSize: 12; color: Theme.fgVariant }
                            }
                        }
                    }
                    MouseArea {
                        id: cardMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: kcm.setVariant(card.modelData[0])
                    }
                }
            }
        }

        // --- colour ----------------------------------------------------------
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 10
            Label { text: i18n("Colour"); font.pixelSize: 13; font.weight: Font.DemiBold; color: Theme.fgVariant }
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: group.implicitHeight
                color: "transparent"
                ColumnLayout {
                    id: group
                    width: parent.width
                    spacing: 2

                    GroupRow {
                        first: true
                        title: i18n("From wallpaper")
                        subtitle: i18n("Colours pulled from the current wallpaper")
                        Repeater {
                            model: kcm.wallpaperSeeds
                            Item {
                                id: ws
                                required property var modelData
                                width: 44; height: 44
                                Ring { on: kcm.seed === "custom" && kcm.hue === ws.modelData.hue }
                                // design: left half a, top-right b, bottom-right c
                                Rectangle { anchors.fill: parent; radius: 22; color: ws.modelData.a }
                                Shape {
                                    anchors.fill: parent
                                    preferredRendererType: Shape.CurveRenderer
                                    ShapePath {
                                        strokeWidth: -1
                                        fillColor: ws.modelData.b
                                        startX: 22; startY: 22
                                        PathLine { x: 22; y: 0 }
                                        PathArc { x: 44; y: 22; radiusX: 22; radiusY: 22 }
                                        PathLine { x: 22; y: 22 }
                                    }
                                    ShapePath {
                                        strokeWidth: -1
                                        fillColor: ws.modelData.c
                                        startX: 22; startY: 22
                                        PathLine { x: 44; y: 22 }
                                        PathArc { x: 22; y: 44; radiusX: 22; radiusY: 22 }
                                        PathLine { x: 22; y: 22 }
                                    }
                                }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: kcm.setCustomHue(ws.modelData.hue) }
                            }
                        }
                    }

                    // accent row + custom panel
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: accentCol.implicitHeight + 28
                        radius: 4
                        color: Theme.scLow
                        ColumnLayout {
                            id: accentCol
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: 14
                            anchors.leftMargin: 16
                            anchors.rightMargin: 16
                            spacing: 14
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 14
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2
                                    Label { text: i18n("Accent colour"); font.pixelSize: 14 }
                                    Label { text: i18n("A preset, or pick your own"); font.pixelSize: 13; color: Theme.fgVariant }
                                }
                                Row {
                                    spacing: 8
                                    Repeater {
                                        model: kcm.presets
                                        Item {
                                            id: dot
                                            required property var modelData
                                            width: 32; height: 32
                                            Ring { on: kcm.seed === dot.modelData.name }
                                            Rectangle { anchors.fill: parent; radius: 16; color: dot.modelData.color }
                                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: kcm.setSeed(dot.modelData.name) }
                                            Accessible.name: dot.modelData.label
                                        }
                                    }
                                    Item {
                                        width: 32; height: 32
                                        Ring { on: kcm.seed === "custom" }
                                        Shape {
                                            anchors.fill: parent
                                            preferredRendererType: Shape.CurveRenderer
                                            ShapePath {
                                                strokeWidth: -1
                                                fillGradient: ConicalGradient {
                                                    centerX: 16; centerY: 16; angle: 90
                                                    GradientStop { position: 0.0; color: kcm.hexFor(0) }
                                                    GradientStop { position: 0.17; color: kcm.hexFor(60) }
                                                    GradientStop { position: 0.33; color: kcm.hexFor(120) }
                                                    GradientStop { position: 0.5; color: kcm.hexFor(180) }
                                                    GradientStop { position: 0.67; color: kcm.hexFor(240) }
                                                    GradientStop { position: 0.83; color: kcm.hexFor(300) }
                                                    GradientStop { position: 1.0; color: kcm.hexFor(359) }
                                                }
                                                PathAngleArc { centerX: 16; centerY: 16; radiusX: 16; radiusY: 16; startAngle: 0; sweepAngle: 360 }
                                            }
                                        }
                                        Rectangle {
                                            anchors.centerIn: parent
                                            width: 20; height: 20; radius: 10
                                            color: Theme.scLow
                                            Sym { anchors.centerIn: parent; name: kcm.seed === "custom" ? "check" : "add"; size: 16 }
                                        }
                                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: kcm.setSeed("custom") }
                                        Accessible.name: i18n("Custom colour")
                                    }
                                }
                            }

                            // custom: hue slider, hex, preview chips, note
                            Rectangle {
                                Layout.fillWidth: true
                                visible: kcm.seed === "custom"
                                implicitHeight: customGrid.implicitHeight + 28
                                radius: Theme.rInner
                                color: Theme.scHigh
                                GridLayout {
                                    id: customGrid
                                    anchors.fill: parent
                                    anchors.margins: 14
                                    columns: 2
                                    columnSpacing: 16
                                    rowSpacing: 14
                                    Item {
                                        id: hueBar
                                        Layout.fillWidth: true
                                        implicitHeight: 28
                                        Rectangle {
                                            anchors.fill: parent
                                            radius: 14
                                            gradient: Gradient {
                                                orientation: Gradient.Horizontal
                                                GradientStop { position: 0.0; color: kcm.hexFor(0) }
                                                GradientStop { position: 0.125; color: kcm.hexFor(45) }
                                                GradientStop { position: 0.25; color: kcm.hexFor(90) }
                                                GradientStop { position: 0.375; color: kcm.hexFor(135) }
                                                GradientStop { position: 0.5; color: kcm.hexFor(180) }
                                                GradientStop { position: 0.625; color: kcm.hexFor(225) }
                                                GradientStop { position: 0.75; color: kcm.hexFor(270) }
                                                GradientStop { position: 0.875; color: kcm.hexFor(315) }
                                                GradientStop { position: 1.0; color: kcm.hexFor(359) }
                                            }
                                        }
                                        // the knob follows the drag; the hue applies on release
                                        property real dragHue: -1
                                        readonly property real shownHue: dragHue >= 0 ? dragHue : kcm.hue
                                        Rectangle {
                                            x: hueBar.shownHue / 360 * hueBar.width - 11
                                            anchors.verticalCenter: parent.verticalCenter
                                            width: 22; height: 22; radius: 11
                                            color: kcm.hexFor(Math.round(hueBar.shownHue))
                                            border.width: 3
                                            border.color: "white"
                                        }
                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            preventStealing: true
                                            function hueAt(x) { return Math.round(Math.max(0, Math.min(1, x / width)) * 359) }
                                            onPressed: m => hueBar.dragHue = hueAt(m.x)
                                            onPositionChanged: m => { if (pressed) hueBar.dragHue = hueAt(m.x) }
                                            onReleased: m => { kcm.setCustomHue(hueAt(m.x)); hueBar.dragHue = -1 }
                                        }
                                    }
                                    Rectangle {
                                        implicitWidth: 124
                                        implicitHeight: 40
                                        radius: 20
                                        color: "transparent"
                                        border.width: 1
                                        border.color: hexInput.ok ? Theme.outline : Theme.err
                                        Row {
                                            anchors.fill: parent
                                            anchors.leftMargin: 14
                                            anchors.rightMargin: 14
                                            spacing: 6
                                            Text { text: "HEX"; font.family: Theme.mono; font.pixelSize: 13; color: Theme.fgVariant; anchors.verticalCenter: parent.verticalCenter }
                                            TextInput {
                                                id: hexInput
                                                property bool ok: true
                                                width: parent.width - 40
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: kcm.hexFor(kcm.hue)
                                                maximumLength: 7
                                                font.family: Theme.mono
                                                font.pixelSize: 13
                                                color: Theme.fg
                                                selectByMouse: true
                                                onEditingFinished: ok = kcm.setHex(text)
                                                onTextEdited: ok = true
                                                // typing breaks the binding; follow the slider again
                                                Connections {
                                                    target: kcm
                                                    function onStateChanged() { if (!hexInput.activeFocus) hexInput.text = kcm.hexFor(kcm.hue) }
                                                }
                                            }
                                        }
                                    }
                                    Flow {
                                        Layout.fillWidth: true
                                        spacing: 8
                                        readonly property var c: kcm.colorsFor(kcm.hue)
                                        Repeater {
                                            model: [[i18n("Primary"), "primary", "onPrimary"], [i18n("Container"), "pc", "onPc"], [i18n("Secondary"), "secC", "onSecC"]]
                                            Rectangle {
                                                required property var modelData
                                                height: 32
                                                width: chipLabel.implicitWidth + 28
                                                radius: 16
                                                color: parent.c[modelData[1]]
                                                Label { id: chipLabel; anchors.centerIn: parent; text: parent.modelData[0]; font.pixelSize: 13; font.weight: Font.DemiBold; color: parent.parent.c[parent.modelData[2]] }
                                            }
                                        }
                                    }
                                    Label {
                                        Layout.preferredWidth: 220
                                        horizontalAlignment: Text.AlignRight
                                        wrapMode: Text.Wrap
                                        elide: Text.ElideNone
                                        font.pixelSize: 12
                                        color: Theme.fgVariant
                                        text: kcm.adjusted
                                              ? i18n("Adjusted: we kept your hue and raised the saturation so buttons and highlights stay readable.")
                                              : i18n("Updates the colours of apps, the boot screen and the bootloader. Those two change after the next restart.")
                                    }
                                }
                            }
                        }
                    }

                    GroupRow {
                        title: i18n("Theme")
                        subtitle: i18n("Auto switches at sunset")
                        Segmented {
                            options: [["dark", i18n("Dark")], ["light", i18n("Light")], ["auto", i18n("Auto")]]
                            current: kcm.theme
                            onPicked: v => kcm.setTheme(v)
                        }
                    }
                    GroupRow {
                        title: i18n("Contrast")
                        subtitle: i18n("High swaps in the high-contrast palette")
                        Segmented {
                            options: [["standard", i18n("Standard")], ["medium", i18n("Medium")], ["high", i18n("High")]]
                            current: kcm.contrast
                            onPicked: v => kcm.setContrast(v)
                        }
                    }
                    GroupRow {
                        last: true
                        title: i18n("App icons")
                        subtitle: i18n("Themed tints every app to the colour; full colour keeps each app's own hue")
                        Segmented {
                            options: [["themed", i18n("Themed")], ["colour", i18n("Full colour")]]
                            current: kcm.iconMode
                            onPicked: v => kcm.setIconMode(v)
                        }
                    }
                }
            }

            // boot splash / bootloader recolouring, and errors
            Label {
                Layout.fillWidth: true
                visible: text !== ""
                wrapMode: Text.Wrap
                elide: Text.ElideNone
                font.pixelSize: 13
                color: kcm.error !== "" || kcm.bootStatus === "failed" ? Theme.err : Theme.fgVariant
                text: kcm.error !== "" ? kcm.error
                    : kcm.bootStatus === "pending" || kcm.bootStatus === "applying" ? i18n("Recolouring the boot screen and bootloader…")
                    : kcm.bootStatus === "done" ? i18n("The boot screen and bootloader take the new colour from the next restart.")
                    : kcm.bootStatus === "failed" ? i18n("The boot screen and bootloader keep their old colour (not authorised, or the update failed).")
                    : ""
            }
        }

        // --- details ---------------------------------------------------------
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 10
            Label { text: i18n("Details"); font.pixelSize: 13; font.weight: Font.DemiBold; color: Theme.fgVariant }
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: details.implicitHeight
                color: "transparent"
                ColumnLayout {
                    id: details
                    width: parent.width
                    spacing: 2
                    Repeater {
                        model: kcm.details
                        Rectangle {
                            id: drow
                            required property var modelData
                            required property int index
                            Layout.fillWidth: true
                            implicitHeight: 60
                            topLeftRadius: index === 0 ? Theme.rCard : 4
                            topRightRadius: index === 0 ? Theme.rCard : 4
                            bottomLeftRadius: index === kcm.details.length - 1 ? Theme.rCard : 4
                            bottomRightRadius: index === kcm.details.length - 1 ? Theme.rCard : 4
                            color: Theme.scLow
                            StateLayer { area: dMouse }
                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 16
                                anchors.rightMargin: 16
                                spacing: 14
                                Sym { name: drow.modelData.icon; size: 22; color: Theme.fgVariant }
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2
                                    Label { text: drow.modelData.title; font.pixelSize: 14 }
                                    Label { text: drow.modelData.value; font.pixelSize: 13; color: Theme.fgVariant; Layout.fillWidth: true }
                                }
                                Sym { name: "chevron_right"; size: 20; color: Theme.fgVariant }
                            }
                            MouseArea {
                                id: dMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: kcm.openModule(drow.modelData.module)
                            }
                        }
                    }
                }
            }
        }
    }
}
