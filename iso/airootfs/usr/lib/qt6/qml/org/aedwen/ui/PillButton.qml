// Pill button: filled (primary), tonal (secondary container), text, or
// danger. Squishes toward a rounded square while pressed (M3E).
import QtQuick

Rectangle {
    id: root
    property string text
    property string icon
    property string kind: "filled"      // filled | tonal | text | danger
    property bool compact: false
    signal clicked()

    readonly property color fg: kind === "filled" ? Theme.primaryFg
                              : kind === "tonal" ? Theme.secCFg
                              : kind === "danger" ? Theme.errCFg
                              : Theme.primary

    implicitHeight: compact ? Theme.controlApp : Theme.controlShell
    implicitWidth: row.implicitWidth + (kind === "text" ? 24 : 40)
    radius: mouse.pressed ? Theme.rInner + 2 : height / 2
    opacity: enabled ? 1 : 0.45
    color: kind === "filled" ? Theme.primary
         : kind === "tonal" ? Theme.secC
         : kind === "danger" ? Theme.errC
         : "transparent"
    Behavior on radius { NumberAnimation { duration: Theme.durShort; easing.type: Easing.OutBack } }

    StateLayer { area: mouse; tint: root.fg }
    Row {
        id: row
        anchors.centerIn: parent
        spacing: 6
        Sym {
            visible: root.icon !== ""
            name: root.icon
            size: 18
            color: root.fg
            anchors.verticalCenter: parent.verticalCenter
        }
        Label {
            text: root.text
            color: root.fg
            font.weight: Font.DemiBold
            anchors.verticalCenter: parent.verticalCenter
        }
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
