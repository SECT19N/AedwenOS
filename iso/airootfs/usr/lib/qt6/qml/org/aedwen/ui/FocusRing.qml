// Keyboard focus ring: 3px primary ring drawn 2px outside its parent.
// Put one inside any control that sets `activeFocusOnTab: true`. Plain
// Items only take focus from Tab (a mouse click on a MouseArea never
// focuses them), so `activeFocus` means keyboard focus; controls also
// drop their focus on a mouse press (see `releaseOnPress`) so the ring never
// shows after a click.
import QtQuick

Rectangle {
    readonly property Item target: parent
    z: 100
    anchors.fill: parent
    anchors.margins: -5            // 2px offset + 3px ring
    color: "transparent"
    border.width: 3
    border.color: Theme.primary
    radius: (target.radius !== undefined ? target.radius : height / 2) + 5
    visible: target.activeFocus
    enabled: false
}
