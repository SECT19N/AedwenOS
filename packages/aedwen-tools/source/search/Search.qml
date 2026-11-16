// The Alt+Space search overlay (Desktop design: SEARCH): a full-screen
// scrim, and 16 % from the top a 640 px card: a 64 px field row (search
// symbol, the query, a close button), a divider, then up to six 56 px
// result rows. Each row has an icon tile (12 px corners in Expressive, a
// circle in baseline), the name, and the kind on the right. The selected
// row is secondary container.
//
// With no query it suggests the dock's apps; otherwise KRunner's runners
// answer (Milou ResultsModel). Up/Down select, Enter runs, Esc or a click
// on the scrim closes. The process stays resident; the window just hides.
import QtQuick
import QtQuick.Window
import QtQuick.Controls as QQC2
import org.kde.layershell as LayerShell
import org.kde.milou as Milou
import org.aedwen.ui

Window {
    id: win
    visible: false
    color: "transparent"
    flags: Qt.FramelessWindowHint
    title: i18n("Search")

    LayerShell.Window.scope: "aedwen-search"
    LayerShell.Window.layer: LayerShell.Window.LayerOverlay
    LayerShell.Window.anchors: LayerShell.Window.AnchorTop | LayerShell.Window.AnchorBottom
                               | LayerShell.Window.AnchorLeft | LayerShell.Window.AnchorRight
    LayerShell.Window.exclusionZone: -1
    LayerShell.Window.keyboardInteractivity: LayerShell.Window.KeyboardInteractivityExclusive
    LayerShell.Window.wantsToBeOnActiveScreen: true

    property int selected: 0
    readonly property bool searching: field.text.trim() !== ""
    readonly property int count: searching ? Math.min(results.count, 6) : controller.suggestions.length

    function open(query) {
        field.text = query || ""
        selected = 0
        if (!visible) {
            visible = true
            card.opacity = 0
            card.scale = 0.96
            enter.restart()
        }
        raise()
        requestActivate()
        field.forceActiveFocus()
        field.cursorPosition = field.text.length
    }
    function close() {
        visible = false
        field.text = ""
    }
    function runSelected() {
        if (count === 0)
            return
        if (searching)
            results.run(results.index(selected, 0))
        else
            controller.launch(controller.suggestions[selected].id)
        close()
    }

    Connections {
        target: controller
        function onShowRequested(query) { win.open(query) }
        function onToggleRequested() { if (win.visible) win.close(); else win.open("") }
    }

    Milou.ResultsModel {
        id: results
        queryString: field.text.trim()
        limit: 6
        onModelReset: win.selected = 0
    }

    // scrim
    Rectangle {
        anchors.fill: parent
        color: Theme.scrim
        MouseArea { anchors.fill: parent; onClicked: win.close() }
    }

    // shadow 0 24 64, 36 %
    Rectangle {
        x: card.x - 24
        y: card.y
        width: card.width + 48
        height: card.height + 48
        radius: card.radius + 24
        color: "transparent"
        opacity: card.opacity
        Repeater {
            model: 8
            Rectangle {
                required property int index
                anchors.centerIn: parent
                anchors.verticalCenterOffset: 0
                width: card.width + index * 6
                height: card.height + index * 6
                radius: card.radius + index * 3
                color: "transparent"
                border.width: 3
                border.color: Qt.rgba(0, 0, 0, 0.045 * (8 - index) / 8)
            }
        }
    }

    Rectangle {
        id: card
        width: Math.min(640, win.width - 32)
        x: (win.width - width) / 2
        y: Math.round(win.height * 0.16)
        height: column.implicitHeight
        radius: Theme.rPop
        color: Theme.scHigh
        clip: true
        transformOrigin: Item.Top

        ParallelAnimation {
            id: enter
            NumberAnimation { target: card; property: "opacity"; to: 1; duration: Theme.durMed }
            NumberAnimation {
                target: card; property: "scale"; to: 1; duration: Theme.dur
                easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.morphEasing
            }
        }

        // swallow clicks so they don't reach the scrim
        MouseArea { anchors.fill: parent }

        Column {
            id: column
            width: parent.width

            Item {
                width: parent.width
                height: 64
                Sym {
                    id: glyph
                    anchors.left: parent.left
                    anchors.leftMargin: 22
                    anchors.verticalCenter: parent.verticalCenter
                    name: "search"
                    size: 24
                    color: Theme.fgVariant
                }
                TextInput {
                    id: field
                    anchors.left: glyph.right
                    anchors.leftMargin: 14
                    anchors.right: closeButton.left
                    anchors.rightMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    font.family: Theme.font
                    font.pixelSize: 18
                    color: Theme.fg
                    selectionColor: Theme.primary
                    selectedTextColor: Theme.primaryFg
                    clip: true
                    focus: true
                    onTextChanged: win.selected = 0
                    Text {
                        anchors.fill: parent
                        verticalAlignment: Text.AlignVCenter
                        visible: field.text === ""
                        text: i18n("Search apps, settings, files")
                        font: field.font
                        color: Theme.fgVariant
                    }
                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Down) {
                            win.selected = Math.min(win.selected + 1, win.count - 1)
                            event.accepted = true
                        } else if (event.key === Qt.Key_Up) {
                            win.selected = Math.max(win.selected - 1, 0)
                            event.accepted = true
                        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            win.runSelected()
                            event.accepted = true
                        } else if (event.key === Qt.Key_Escape) {
                            win.close()
                            event.accepted = true
                        }
                    }
                }
                IconButton {
                    id: closeButton
                    anchors.right: parent.right
                    anchors.rightMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    icon: "close"
                    size: 36
                    iconSize: 22
                    onClicked: win.close()
                }
            }

            Rectangle { width: parent.width; height: 1; color: Theme.outlineV }

            Column {
                width: parent.width
                padding: 8
                spacing: 2

                component Row_: Rectangle {
                    id: row
                    property int position
                    property string name
                    property string kind
                    property var icon
                    signal activated()
                    readonly property bool current: position === win.selected
                    width: parent.width - 16
                    height: 56
                    radius: Theme.rItem
                    color: current ? Theme.secC : "transparent"
                    StateLayer { area: rowMouse; tint: row.current ? Theme.secCFg : Theme.fg }
                    AppIcon {
                        id: tile
                        anchors.left: parent.left
                        anchors.leftMargin: 14
                        anchors.verticalCenter: parent.verticalCenter
                        size: 36
                        radius: Theme.expressive ? 12 : 18
                        source: row.icon || "application-x-executable"
                    }
                    Label {
                        anchors.left: tile.right
                        anchors.leftMargin: 14
                        anchors.right: kindLabel.left
                        anchors.rightMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        text: row.name
                        font.pixelSize: 15
                        font.weight: Font.Medium
                        color: row.current ? Theme.secCFg : Theme.fg
                    }
                    Label {
                        id: kindLabel
                        anchors.right: parent.right
                        anchors.rightMargin: 14
                        anchors.verticalCenter: parent.verticalCenter
                        width: Math.min(implicitWidth, row.width * 0.35)
                        text: row.kind
                        font.pixelSize: 13
                        color: Theme.fgVariant
                    }
                    MouseArea {
                        id: rowMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: win.selected = row.position
                        onClicked: row.activated()
                    }
                }

                Repeater {
                    model: win.searching ? null : controller.suggestions
                    Row_ {
                        required property var modelData
                        required property int index
                        position: index
                        name: modelData.name
                        kind: modelData.kind
                        icon: modelData.icon
                        onActivated: { win.selected = index; win.runSelected() }
                    }
                }
                Repeater {
                    model: win.searching ? results : null
                    Row_ {
                        required property int index
                        required property var model
                        visible: index < 6
                        position: index
                        name: model.display || ""
                        kind: model.category || model.subtext || ""
                        icon: model.decoration
                        onActivated: { win.selected = index; win.runSelected() }
                    }
                }
                Label {
                    visible: win.searching && results.count === 0 && !results.querying
                    width: parent.width - 16
                    height: 60
                    horizontalAlignment: Text.AlignHCenter
                    text: i18n("No results")
                    color: Theme.fgVariant
                }
            }
        }
    }

    onActiveChanged: if (!active && visible) close()
}
