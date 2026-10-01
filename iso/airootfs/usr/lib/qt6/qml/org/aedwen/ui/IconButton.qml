// Round icon button (standard / tonal / filled). `selected` gives the
// secondary-container fill used for toggled header buttons.
import QtQuick

Rectangle {
    id: root
    property string icon
    property real fill: 0
    property string kind: "standard"    // standard | tonal | filled
    property bool selected: false
    property int size: Theme.controlApp
    property int iconSize: 20
    property string tooltip
    signal clicked()

    readonly property color fg: kind === "filled" ? Theme.primaryFg
                              : (kind === "tonal" || selected) ? Theme.secCFg
                              : Theme.fgVariant

    implicitWidth: size
    implicitHeight: size
    radius: mouse.pressed ? Theme.rInner : height / 2
    color: kind === "filled" ? Theme.primary
         : (kind === "tonal" || selected) ? Theme.secC
         : "transparent"
    opacity: enabled ? 1 : 0.45
    Behavior on radius { NumberAnimation { duration: Theme.durShort; easing.type: Easing.OutBack } }
    Behavior on color { ColorAnimation { duration: Theme.durShort } }

    StateLayer { area: mouse; tint: root.fg }
    Sym {
        anchors.centerIn: parent
        name: root.icon
        size: root.iconSize
        fill: root.selected ? 1 : root.fill
        color: root.fg
    }
    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        enabled: root.enabled
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
