// Calendar popup: big time and long date, then a month grid (today is a
// primary circle) with month navigation.
import QtQuick
import QtQuick.Layouts
import org.aedwen.ui

Item {
    id: popup
    required property var clock
    property date month: new Date(clock.now.getFullYear(), clock.now.getMonth(), 1)

    Layout.minimumWidth: 320
    Layout.preferredWidth: 320
    Layout.minimumHeight: col.implicitHeight + 16
    Layout.preferredHeight: col.implicitHeight + 16

    Connections {
        target: popup.clock
        function onExpandedChanged() {
            if (popup.clock.expanded)
                popup.month = new Date(popup.clock.now.getFullYear(), popup.clock.now.getMonth(), 1)
        }
    }

    readonly property int firstDay: clock.locale.firstDayOfWeek % 7      // 0 = Sunday
    readonly property var days: {
        const y = month.getFullYear(), m = month.getMonth()
        const lead = (new Date(y, m, 1).getDay() - firstDay + 7) % 7
        const count = new Date(y, m + 1, 0).getDate()
        const out = []
        for (let i = 0; i < lead; ++i) out.push(0)
        for (let d = 1; d <= count; ++d) out.push(d)
        return out
    }

    ColumnLayout {
        id: col
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 8
        spacing: 12

        ColumnLayout {
            spacing: 2
            Label {
                role: "display"
                text: popup.clock.timeString(popup.clock.now)
            }
            Label {
                text: popup.clock.now.toLocaleDateString(popup.clock.locale, Locale.LongFormat)
                color: Theme.fgVariant
            }
        }
        Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Theme.outlineV }
        RowLayout {
            Layout.fillWidth: true
            Label {
                Layout.fillWidth: true
                text: popup.month.toLocaleDateString(popup.clock.locale, "MMMM yyyy")
                font.weight: Font.DemiBold
            }
            IconButton {
                icon: "today"
                size: 32
                iconSize: 18
                visible: popup.month.getMonth() !== popup.clock.now.getMonth()
                         || popup.month.getFullYear() !== popup.clock.now.getFullYear()
                onClicked: popup.month = new Date(popup.clock.now.getFullYear(), popup.clock.now.getMonth(), 1)
            }
            IconButton {
                icon: "chevron_left"
                size: 32
                onClicked: popup.month = new Date(popup.month.getFullYear(), popup.month.getMonth() - 1, 1)
            }
            IconButton {
                icon: "chevron_right"
                size: 32
                onClicked: popup.month = new Date(popup.month.getFullYear(), popup.month.getMonth() + 1, 1)
            }
        }
        Grid {
            id: grid
            columns: 7
            Layout.fillWidth: true
            readonly property real cell: width / 7
            Repeater {
                model: 7
                Label {
                    required property int index
                    width: grid.cell
                    height: 28
                    horizontalAlignment: Text.AlignHCenter
                    role: "caption"
                    text: popup.clock.locale.dayName((index + popup.firstDay) % 7, Locale.NarrowFormat)
                }
            }
            Repeater {
                model: popup.days
                Item {
                    required property var modelData
                    readonly property bool today: modelData === popup.clock.now.getDate()
                                                  && popup.month.getMonth() === popup.clock.now.getMonth()
                                                  && popup.month.getFullYear() === popup.clock.now.getFullYear()
                    width: grid.cell
                    height: 38
                    Rectangle {
                        anchors.centerIn: parent
                        width: 34
                        height: 34
                        radius: 17
                        visible: parent.modelData > 0
                        color: parent.today ? Theme.primary : "transparent"
                        Label {
                            anchors.centerIn: parent
                            text: parent.parent.modelData
                            color: parent.parent.today ? Theme.primaryFg : Theme.fg
                            font.weight: parent.parent.today ? Font.DemiBold : Font.Normal
                            font.pixelSize: 13
                        }
                    }
                }
            }
        }
        WheelHandler {
            onWheel: event => popup.month = new Date(popup.month.getFullYear(),
                                                    popup.month.getMonth() + (event.angleDelta.y < 0 ? 1 : -1), 1)
        }
    }
}
