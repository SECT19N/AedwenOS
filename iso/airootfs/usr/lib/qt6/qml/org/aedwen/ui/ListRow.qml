// Selectable/clickable list row with optional leading symbol or (tinted)
// app icon, subtitle and trailing content. Selected rows use the secondary
// container.
import QtQuick

Rectangle {
    id: root
    property string title
    property string subtitle
    property string icon            // Material Symbol name
    property var appIcon            // icon name, path or QIcon (AppIcon tile)
    property bool selected: false
    property alias trailing: trailingSlot.data
    signal clicked()

    implicitWidth: 300
    implicitHeight: subtitle || appIcon ? 52 : 44
    radius: Theme.rInner
    color: selected ? Theme.secC : "transparent"

    StateLayer { area: mouse; tint: root.selected ? Theme.secCFg : Theme.fg }

    Row {
        id: lead
        anchors.left: parent.left
        anchors.leftMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        spacing: 12
        Sym {
            visible: root.icon !== ""
            name: root.icon
            fill: root.selected ? 1 : 0
            color: root.selected ? Theme.secCFg : Theme.fgVariant
            anchors.verticalCenter: parent.verticalCenter
        }
        AppIcon {
            visible: !!root.appIcon
            source: root.appIcon || ""
            size: 32
            anchors.verticalCenter: parent.verticalCenter
        }
    }
    Column {
        anchors.left: lead.right
        anchors.leftMargin: lead.width > 0 ? 12 : 0
        anchors.right: trailingSlot.left
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        spacing: 1
        Label {
            width: parent.width
            text: root.title
            color: root.selected ? Theme.secCFg : Theme.fg
            font.weight: root.selected ? Font.DemiBold : Font.Normal
        }
        Label {
            visible: root.subtitle !== ""
            width: parent.width
            role: "caption"
            text: root.subtitle
            color: root.selected ? Theme.secCFg : Theme.fgVariant
        }
    }
    Row {
        id: trailingSlot
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8
    }
    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
        z: -1
    }
}
