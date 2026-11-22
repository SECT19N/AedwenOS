// Hover/press overlay (8% / 12% of `color`; stronger in high contrast) filling its parent with the
// parent's radius. Put it inside any Rectangle and point `area` at the
// MouseArea/HoverHandler that drives it.
import QtQuick

Rectangle {
    property var area: null
    property color tint: Theme.fg

    anchors.fill: parent
    radius: parent.radius !== undefined ? parent.radius : 0
    color: tint
    opacity: !area || !parent.enabled ? 0 : area.pressed ? Theme.pressOpacity : area.containsMouse ? Theme.hoverOpacity : 0
    Behavior on opacity { NumberAnimation { duration: Theme.durShort } }
}
