// AedwenOS window switcher (Alt+Tab), from the AedwenOS Desktop design
// ("ALT SWITCHER"): a centred surface-container-high card, one 148 px card
// per window with its app icon tile, title and "Desktop N" / "Minimized".
// The selected window gets a secondary-container card and its tile morphs
// from an 18 px rounded square to a primary circle.
//
// Selected by kwinrc [TabBox] LayoutName=aedwen (etc/xdg/kwinrc and the
// global themes' defaults). KWin itself handles Alt+Tab / Alt+` cycling and
// moves currentIndex; this file only draws it.
import QtQuick
import QtQuick.Effects
import org.kde.kirigami as Kirigami
import org.kde.kwin as KWin
import org.aedwen.ui

KWin.TabBoxSwitcher {
    id: tabBox

    currentIndex: (instantiator.object as SwitcherWindow)?.currentIndex ?? currentIndex

    Instantiator {
        id: instantiator
        active: tabBox.visible
        delegate: SwitcherWindow { }
    }

    component SwitcherWindow: Window {
        id: win

        property alias currentIndex: list.currentIndex

        // room around the card for its shadow
        readonly property int shadowPad: 40
        readonly property int cardPad: 14
        readonly property int itemWidth: 148
        readonly property int itemSpacing: 8

        flags: Qt.ToolTip | Qt.X11BypassWindowManagerHint | Qt.FramelessWindowHint
        color: "transparent"
        visible: tabBox.visible
        width: card.width + 2 * shadowPad
        height: card.height + 2 * shadowPad
        x: tabBox.screenGeometry.x + (tabBox.screenGeometry.width - width) / 2
        y: tabBox.screenGeometry.y + (tabBox.screenGeometry.height - height) / 2

        Rectangle {
            id: card
            x: win.shadowPad
            y: win.shadowPad
            width: Math.max(list.width, hint.implicitWidth) + 2 * win.cardPad
            height: col.height + 2 * win.cardPad
            radius: Theme.rPop
            color: Theme.scHigh

            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: Qt.rgba(0, 0, 0, 0.4)
                shadowBlur: 1.0
                shadowVerticalOffset: 16
                autoPaddingEnabled: true
            }

            Column {
                id: col
                x: win.cardPad
                y: win.cardPad
                spacing: 10

                ListView {
                    id: list
                    anchors.horizontalCenter: parent.horizontalCenter
                    readonly property int fullWidth: count * (win.itemWidth + win.itemSpacing) - win.itemSpacing
                    width: count === 0 ? 360 : Math.min(fullWidth, tabBox.screenGeometry.width * 0.9 - 2 * win.cardPad)
                    height: 150
                    orientation: ListView.Horizontal
                    spacing: win.itemSpacing
                    interactive: false
                    focus: true
                    keyNavigationWraps: true
                    highlightFollowsCurrentItem: true
                    highlightMoveDuration: Theme.durShort
                    preferredHighlightBegin: width / 2 - win.itemWidth / 2
                    preferredHighlightEnd: width / 2 + win.itemWidth / 2
                    highlightRangeMode: fullWidth > width ? ListView.ApplyRange : ListView.NoHighlightRange
                    currentIndex: tabBox.currentIndex
                    model: tabBox.model

                    delegate: Rectangle {
                        id: item
                        readonly property bool selected: ListView.isCurrentItem

                        width: win.itemWidth
                        height: list.height
                        radius: Theme.rCard
                        color: selected ? Theme.secC : "transparent"
                        Behavior on color { ColorAnimation { duration: Theme.durShort } }

                        Accessible.name: model.caption
                        Accessible.role: Accessible.ListItem

                        Column {
                            anchors.horizontalCenter: parent.horizontalCenter
                            y: 18
                            spacing: 10

                            AppIcon {
                                id: tile
                                anchors.horizontalCenter: parent.horizontalCenter
                                size: 64
                                iconScale: item.selected ? 0.62 : 0.7
                                source: model.icon
                                // 18 px rounded square -> circle when selected
                                radius: item.selected ? size / 2 : 18
                                color: item.selected ? Theme.primary : Theme.scHighest
                                border.width: item.selected ? 0 : 1
                                Behavior on radius {
                                    NumberAnimation {
                                        duration: Theme.dur
                                        easing.type: Easing.BezierSpline
                                        easing.bezierCurve: Theme.spring
                                    }
                                }
                                Behavior on iconScale { NumberAnimation { duration: Theme.durMed } }
                            }

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: win.itemWidth - 20
                                horizontalAlignment: Text.AlignHCenter
                                text: model.caption
                                textFormat: Text.PlainText
                                elide: Text.ElideRight
                                font.family: Theme.font
                                font.pixelSize: 13
                                font.weight: Font.DemiBold
                                color: item.selected ? Theme.secCFg : Theme.fg
                            }

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: win.itemWidth - 20
                                horizontalAlignment: Text.AlignHCenter
                                text: model.minimized ? i18nd("kwin", "Minimized") : (model.desktopName ?? "")
                                textFormat: Text.PlainText
                                elide: Text.ElideRight
                                font.family: Theme.font
                                font.pixelSize: 11
                                opacity: 0.8
                                color: item.selected ? Theme.secCFg : Theme.fg
                            }
                        }

                        TapHandler {
                            onTapped: tabBox.model.activate(index)
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: list.count === 0
                        text: i18ndc("kwin", "@info:placeholder no entries in the task switcher", "No open windows")
                        font.family: Theme.font
                        font.pixelSize: 14
                        color: Theme.fgVariant
                    }

                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Left) {
                            LayoutMirroring.enabled ? incrementCurrentIndex() : decrementCurrentIndex()
                        } else if (event.key === Qt.Key_Right) {
                            LayoutMirroring.enabled ? decrementCurrentIndex() : incrementCurrentIndex()
                        }
                    }
                }

                Text {
                    id: hint
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Hold Alt · press Tab or ` to cycle · release to switch"
                    font.family: Theme.font
                    font.pixelSize: 12
                    color: Theme.fgVariant
                }
            }
        }

        Connections {
            target: tabBox
            function onCurrentIndexChanged() {
                list.currentIndex = tabBox.currentIndex
            }
        }

        onSceneGraphError: () => {
            // Left blank on purpose: otherwise QtQuick may qFatal() on a
            // graphics reset, taking KWin with it.
        }
    }
}
