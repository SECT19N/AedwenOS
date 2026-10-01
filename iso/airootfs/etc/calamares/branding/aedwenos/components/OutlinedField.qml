// Outlined text field with a floating label (design: "Line edits").
// 2px primary border while focused, error colour + helper text on error.
import QtQuick
import ".."

Column {
    id: root
    property string label
    property alias text: input.text
    property alias validator: input.validator
    property alias acceptableInput: input.acceptableInput
    property bool password: false
    property bool pill: false
    property string leadingIcon
    property string trailingIcon
    property color trailingColor: Theme.fgVariant
    property string placeholder
    property string helper
    property bool error: false
    property bool readOnly: false
    signal textEdited()

    spacing: 5
    width: 260

    function forceActiveFocus() { input.forceActiveFocus() }

    Rectangle {
        id: box
        width: parent.width
        height: 44
        radius: root.pill ? height / 2 : Theme.rInner
        color: "transparent"
        border.width: input.activeFocus || root.error ? 2 : 1
        border.color: root.error ? Theme.err : input.activeFocus ? Theme.primary : Theme.outline

        Row {
            anchors.fill: parent
            anchors.leftMargin: root.leadingIcon ? 12 : 14
            anchors.rightMargin: 12
            spacing: 10
            Sym {
                visible: root.leadingIcon !== ""
                name: root.leadingIcon
                color: Theme.fgVariant
                anchors.verticalCenter: parent.verticalCenter
            }
            TextInput {
                id: input
                width: parent.width - (root.leadingIcon ? 30 : 0) - (trailing.visible ? 30 : 0)
                anchors.verticalCenter: parent.verticalCenter
                color: Theme.fg
                selectionColor: Theme.primary
                selectedTextColor: Theme.primaryFg
                font.family: Theme.font
                font.pixelSize: 14
                font.letterSpacing: root.password && !reveal.shown && text.length ? 1 : 0
                echoMode: root.password && !reveal.shown ? TextInput.Password : TextInput.Normal
                passwordCharacter: "•"
                readOnly: root.readOnly
                clip: true
                onTextEdited: root.textEdited()

                Text {
                    visible: !input.text && !input.activeFocus
                    text: root.placeholder
                    color: Theme.fgVariant
                    font: input.font
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
            Sym {
                id: trailing
                // Password fields get a show/hide toggle unless a status icon is set.
                QtObject { id: reveal; property bool shown: false }
                visible: root.trailingIcon !== "" || root.password
                name: root.trailingIcon !== "" ? root.trailingIcon : (reveal.shown ? "visibility_off" : "visibility")
                fill: root.trailingIcon !== "" ? 1 : 0
                color: root.error ? Theme.err : root.trailingColor
                anchors.verticalCenter: parent.verticalCenter
                MouseArea {
                    anchors.fill: parent
                    enabled: root.password && root.trailingIcon === ""
                    cursorShape: Qt.PointingHandCursor
                    onClicked: reveal.shown = !reveal.shown
                }
            }
        }

        // Floating label notched into the top border.
        Rectangle {
            visible: root.label !== ""
            x: 9
            y: -8
            width: labelText.implicitWidth + 8
            height: 16
            color: Theme.surface
            Text {
                id: labelText
                anchors.centerIn: parent
                text: root.label
                color: root.error ? Theme.err : input.activeFocus ? Theme.primary : Theme.fgVariant
                font.family: Theme.font
                font.pixelSize: 12
                font.weight: Font.DemiBold
            }
        }
        MouseArea {
            anchors.fill: parent
            anchors.rightMargin: trailing.visible ? 40 : 0
            cursorShape: Qt.IBeamCursor
            onPressed: (mouse) => { input.forceActiveFocus(); mouse.accepted = false }
        }
    }
    Text {
        visible: root.helper !== ""
        width: parent.width
        leftPadding: 12
        text: root.helper
        wrapMode: Text.WordWrap
        color: root.error ? Theme.err : Theme.fgVariant
        font.family: Theme.font
        font.pixelSize: 12
    }
}
