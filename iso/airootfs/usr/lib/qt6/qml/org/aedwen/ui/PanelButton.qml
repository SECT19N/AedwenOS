// A top-bar item: pill-shaped hover/press layer, secondary-container fill
// while its popup is open (`active`). Put any content inside.
//
// It follows the panel's thickness: `size` is the height its parent (the
// widget's compact representation, as tall as the panel minus the frame
// margins) gives it, and `iconSize` / `textSize` scale from that, so
// resizing the panel resizes every item in it. Contents bind to them
// rather than to fixed pixel sizes.
import QtQuick

Rectangle {
    id: root
    activeFocusOnTab: true
    Keys.onReturnPressed: root.clicked({ button: Qt.LeftButton })
    Keys.onEnterPressed: root.clicked({ button: Qt.LeftButton })
    Keys.onSpacePressed: root.clicked({ button: Qt.LeftButton })
    property bool active: false
    property int size: parent ? Math.max(20, Math.min(64, parent.height)) : 32
    property int padding: Math.round(size * 0.31)
    readonly property int iconSize: Math.round(size * 0.56)
    readonly property int textSize: Math.max(11, Math.round(size * 0.42))
    default property alias content: row.data
    readonly property alias containsMouse: mouse.containsMouse
    signal clicked(var mouse)

    implicitWidth: row.implicitWidth + padding * 2
    implicitHeight: size
    radius: height / 2
    color: active ? Theme.secC : "transparent"
    Behavior on color { ColorAnimation { duration: Theme.durShort } }

    StateLayer { area: mouse; tint: root.active ? Theme.secCFg : Theme.fg }
    Row {
        id: row
        anchors.centerIn: parent
        spacing: Math.round(root.size * 0.25)
    }
    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        onPressed: root.focus = false
        onClicked: mouse => root.clicked(mouse)
    }
    FocusRing {}
}
