// Users step ("Who's using this computer?"): avatar initial, name /
// username / computer name, password with a strength meter, and switches
// for automatic login and reusing the password for admin (root) tasks.
import io.calamares.core 1.0
import io.calamares.ui 1.0
import QtQuick
import QtQuick.Layouts
import "."

Rectangle {
    id: page
    color: Theme.surface

    // 0-4 bars for the meter; Calamares' own checks decide validity.
    function strength(pw) {
        if (!pw) return 0
        let s = pw.length >= 12 ? 2 : pw.length >= 8 ? 1 : 0
        if (/[a-z]/.test(pw) && /[A-Z]/.test(pw)) s++
        if (/[0-9]/.test(pw) || /[^A-Za-z0-9]/.test(pw)) s++
        return Math.max(1, Math.min(4, s))
    }
    readonly property int score: strength(pw.text)
    readonly property var scoreNames: [qsTr("Weak"), qsTr("Fair"), qsTr("Good"), qsTr("Strong")]

    Flickable {
        id: flick
        anchors.fill: parent
        contentHeight: content.implicitHeight + 36
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: content
            x: 32
            y: 28
            width: flick.width - 64
            spacing: 22

            PageHeader {
                Layout.fillWidth: true
                title: qsTr("Who’s using this computer?")
                description: qsTr("You can add more people in Settings later.")
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 28

                // Avatar: first letter of the name in the asymmetric shape.
                Rectangle {
                    Layout.alignment: Qt.AlignTop
                    width: 88
                    height: 88
                    color: Theme.pc
                    topLeftRadius: 44
                    topRightRadius: 44
                    bottomRightRadius: 44
                    bottomLeftRadius: 19
                    Text {
                        anchors.centerIn: parent
                        text: fullName.text ? fullName.text.charAt(0).toUpperCase() : ""
                        color: Theme.pcFg
                        font.family: Theme.font
                        font.pixelSize: 38
                        font.weight: Font.Bold
                    }
                    Sym {
                        anchors.centerIn: parent
                        visible: !fullName.text
                        name: "person"
                        fill: 1
                        size: 44
                        color: Theme.pcFg
                    }
                }

                GridLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: 8
                    columns: 2
                    columnSpacing: 14
                    rowSpacing: 22

                    OutlinedField {
                        id: fullName
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignTop
                        label: qsTr("Your name")
                        text: config.fullName
                        readOnly: !config.isEditable("fullName")
                        onTextEdited: config.setFullName(text)
                    }
                    OutlinedField {
                        id: login
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignTop
                        label: qsTr("Username")
                        text: config.loginName
                        readOnly: !config.isEditable("loginName")
                        validator: RegularExpressionValidator { regularExpression: /[a-z_][a-z0-9_-]*[$]?/ }
                        error: config.loginNameStatus !== ""
                        helper: config.loginNameStatus !== "" ? config.loginNameStatus
                              : text ? qsTr("Your home folder will be /home/%1").arg(text) : ""
                        onTextEdited: config.setLoginName(text)
                    }
                    OutlinedField {
                        Layout.fillWidth: true
                        Layout.columnSpan: 2
                        label: qsTr("Computer name")
                        text: config.hostname
                        validator: RegularExpressionValidator { regularExpression: /[a-zA-Z0-9][-a-zA-Z0-9_]*/ }
                        error: config.hostnameStatus !== ""
                        helper: config.hostnameStatus
                        onTextEdited: config.setHostName(text)
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignTop
                        spacing: 6
                        OutlinedField {
                            id: pw
                            Layout.fillWidth: true
                            label: qsTr("Password")
                            password: true
                            text: config.userPassword
                            onTextEdited: config.setUserPassword(text)
                        }
                        RowLayout {
                            visible: pw.text !== ""
                            Layout.fillWidth: true
                            Layout.leftMargin: 2
                            spacing: 4
                            Repeater {
                                model: 4
                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 4
                                    radius: 2
                                    color: index < page.score ? (page.score <= 1 ? Theme.err : Theme.primary) : Theme.secC
                                }
                            }
                            Text {
                                leftPadding: 6
                                text: page.scoreNames[Math.max(0, page.score - 1)]
                                color: page.score <= 1 ? Theme.err : Theme.primary
                                font.family: Theme.font
                                font.pixelSize: 12
                                font.weight: Font.DemiBold
                            }
                        }
                    }
                    OutlinedField {
                        id: pw2
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignTop
                        label: qsTr("Confirm password")
                        password: true
                        text: config.userPasswordSecondary
                        readonly property bool matches: text !== "" && text === pw.text
                        trailingIcon: matches ? "check_circle" : ""
                        trailingColor: Theme.primary
                        error: text !== "" && !matches
                        helper: error ? qsTr("Passwords don't match") : ""
                        onTextEdited: config.setUserPasswordSecondary(text)
                    }
                }
            }

            // Calamares' password-policy verdict (too short, too simple, ...).
            Text {
                Layout.fillWidth: true
                visible: pw.text !== "" && pw2.text !== "" && config.userPasswordValidity !== 0 && config.userPasswordMessage !== ""
                text: config.userPasswordMessage
                wrapMode: Text.WordWrap
                color: config.userPasswordValidity === 1 ? Theme.fgVariant : Theme.err
                font.family: Theme.font
                font.pixelSize: 13
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                SwitchRow {
                    Layout.fillWidth: true
                    topLeftRadius: Theme.rCard
                    topRightRadius: Theme.rCard
                    title: qsTr("Log in automatically")
                    description: qsTr("Skip the login screen on this computer")
                    checked: config.doAutoLogin
                    onToggled: (c) => config.setAutoLogin(c)
                }
                SwitchRow {
                    Layout.fillWidth: true
                    visible: config.writeRootPassword
                    bottomLeftRadius: Theme.rCard
                    bottomRightRadius: Theme.rCard
                    title: qsTr("Use this password for admin tasks")
                    description: qsTr("Otherwise you’ll set a separate root password")
                    checked: config.reuseUserPasswordForRoot
                    onToggled: (c) => config.setReuseUserPasswordForRoot(c)
                }
            }

            RowLayout {
                Layout.fillWidth: true
                visible: config.writeRootPassword && !config.reuseUserPasswordForRoot
                spacing: 14
                OutlinedField {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignTop
                    label: qsTr("Root password")
                    password: true
                    text: config.rootPassword
                    onTextEdited: config.setRootPassword(text)
                }
                OutlinedField {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignTop
                    label: qsTr("Confirm root password")
                    password: true
                    text: config.rootPasswordSecondary
                    error: config.rootPasswordValidity === 2 && text !== ""
                    helper: error ? config.rootPasswordMessage : ""
                    onTextEdited: config.setRootPasswordSecondary(text)
                }
            }
        }
    }
}
