// One row of a Quick Settings details page (Desktop design): at least 60 px,
// symbol / name + sub-line / trailing symbol, primary container when `on`
// and surface-container-high otherwise. Rows are grouped: in Expressive the
// first and last keep 20 px outer corners and every inner corner is 4 px;
// baseline rows are separate 12 px cards. Set `position` and `count`.
import QtQuick
import QtQuick.Layouts
import org.aedwen.ui

Rectangle {
    id: row
    property string icon
    property string name
    property string sub
    property string trail
    property bool on: false
    property int position: 0
    property int count: 1
    // anything extra under the row (e.g. a password field)
    default property alias extra: extraSlot.data
    signal clicked()
    signal trailClicked()

    readonly property bool first: position === 0
    readonly property bool last: position === count - 1
    readonly property int outer: Theme.expressive ? 20 : 12
    readonly property int inner: Theme.expressive ? 4 : 12
    readonly property color fg: on ? Theme.pcFg : Theme.fg

    Layout.fillWidth: true
    implicitHeight: Math.max(60, content.implicitHeight + 20) + (extraSlot.children.length && extraSlot.visibleChildren.length ? extraSlot.implicitHeight + 10 : 0)
    topLeftRadius: first ? outer : inner
    topRightRadius: first ? outer : inner
    bottomLeftRadius: last ? outer : inner
    bottomRightRadius: last ? outer : inner
    color: on ? Theme.pc : Theme.scHigh
    Behavior on color { ColorAnimation { duration: 200 } }

    // brightness(1.06) on hover in the design
    Rectangle {
        anchors.fill: parent
        topLeftRadius: row.topLeftRadius
        topRightRadius: row.topRightRadius
        bottomLeftRadius: row.bottomLeftRadius
        bottomRightRadius: row.bottomRightRadius
        color: row.fg
        opacity: mouse.pressed ? 0.10 : mouse.containsMouse ? 0.06 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.durShort } }
    }
    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: row.clicked()
    }

    RowLayout {
        id: content
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.leftMargin: 14
        anchors.rightMargin: 14
        height: Math.max(60, implicitHeight + 20)
        spacing: 14
        Sym { name: row.icon; size: 22; fill: 1; color: row.fg }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0
            Label { Layout.fillWidth: true; text: row.name; font.pixelSize: 14; font.weight: Font.DemiBold; color: row.fg }
            Label { Layout.fillWidth: true; visible: text !== ""; text: row.sub; font.pixelSize: 12; color: row.fg; opacity: 0.8 }
        }
        Sym {
            visible: row.trail !== ""
            name: row.trail
            size: 19
            color: row.fg
            opacity: 0.75
            MouseArea {
                anchors.fill: parent
                anchors.margins: -8
                cursorShape: Qt.PointingHandCursor
                onClicked: row.trailClicked()
            }
        }
    }
    Item {
        id: extraSlot
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 10
        implicitHeight: childrenRect.height
    }
}
