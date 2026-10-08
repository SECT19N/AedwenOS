// AedwenOS login screen (SDDM): Plasma's Breeze SDDM theme with the
// AedwenOS look, matching the lock screen -- the design's pill password
// field and a round primary login button (System Surfaces §07). Logic is
// Breeze's; keep in sync with plasma-desktop's sddm-theme when it changes.
import org.kde.breeze.components
import org.aedwen.ui as Ae

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2

import org.kde.plasma.components as PlasmaComponents3
import org.kde.plasma.extras as PlasmaExtras
import org.kde.kirigami as Kirigami

SessionManagementScreen {
    id: root
    property Item mainPasswordBox: passwordBox

    property bool showUsernamePrompt: !showUserList

    property string lastUserName
    property bool loginScreenUiVisible: false

    //the y position that should be ensured visible when the on screen keyboard is visible
    property int visibleBoundary: mapFromItem(loginButton, 0, 0).y
    onHeightChanged: visibleBoundary = mapFromItem(loginButton, 0, 0).y + loginButton.height + Kirigami.Units.smallSpacing

    property real fontSize: Kirigami.Theme.defaultFont.pointSize

    signal loginRequest(string username, string password)

    onShowUsernamePromptChanged: {
        if (!showUsernamePrompt) {
            lastUserName = ""
        }
    }

    onUserSelected: {
        // Don't startLogin() here, because the signal is connected to the
        // Escape key as well, for which it wouldn't make sense to trigger
        // login.
        passwordBox.clear()
        focusFirstVisibleFormControl();
    }

    QQC2.StackView.onActivating: {
        // Controls are not visible yet.
        Qt.callLater(focusFirstVisibleFormControl);
    }

    function focusFirstVisibleFormControl() {
        const nextControl = (userNameInput.visible
            ? userNameInput
            : (passwordBox.visible
                ? passwordBox
                : loginButton));
        // Using TabFocusReason, so that the loginButton gets the visual highlight.
        nextControl.forceActiveFocus(Qt.TabFocusReason);
    }

    /*
     * Login has been requested with the following username and password
     * If username field is visible, it will be taken from that, otherwise from the "name" property of the currentIndex
     */
    function startLogin() {
        const username = showUsernamePrompt ? userNameInput.text : userList.selectedUser
        const password = passwordBox.text

        footer.enabled = false
        mainStack.enabled = false
        userListComponent.userList.opacity = 0.75

        // This is partly because it looks nicer, but more importantly it
        // works round a Qt bug that can trigger if the app is closed with a
        // TextField focused.
        //
        // See https://bugreports.qt.io/browse/QTBUG-55460
        loginButton.forceActiveFocus();
        loginRequest(username, password);
    }

    PlasmaComponents3.TextField {
        id: userNameInput
        font.pointSize: fontSize + 1
        Layout.fillWidth: true

        text: lastUserName
        visible: showUsernamePrompt
        focus: showUsernamePrompt && !lastUserName //if there's a username prompt it gets focus first, otherwise password does
        placeholderText: i18ndc("plasma-desktop-sddm-theme", "@info:placeholder in textfield", "Username")

        onAccepted: {
            if (root.loginScreenUiVisible) {
                passwordBox.forceActiveFocus()
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true

        PlasmaExtras.PasswordField {
            id: passwordBox
            font.pointSize: fontSize + 1
            Layout.fillWidth: true
            implicitHeight: 52
            leftPadding: 22
            color: Ae.Theme.fg
            placeholderTextColor: Ae.Theme.fgVariant
            background: Rectangle {
                radius: height / 2
                color: Ae.Theme.alpha(Ae.Theme.scHigh, 0.92)
                border.width: passwordBox.activeFocus ? 2 : 1
                border.color: passwordBox.activeFocus ? Ae.Theme.primary : Ae.Theme.outline
                Behavior on border.color { ColorAnimation { duration: Ae.Theme.durShort } }
            }

            placeholderText: i18ndc("plasma-desktop-sddm-theme",  "@info:placeholder in textfield", "Password")
            focus: !showUsernamePrompt || lastUserName

            // Disable reveal password action because SDDM does not have the breeze icon set loaded
            rightActions: []

            onAccepted: {
                if (root.loginScreenUiVisible) {
                    startLogin();
                }
            }

            visible: root.showUsernamePrompt || userList.currentItem.needsPassword

            Keys.onEscapePressed: {
                mainStack.currentItem.forceActiveFocus();
            }

            //if empty and left or right is pressed change selection in user switch
            //this cannot be in keys.onLeftPressed as then it doesn't reach the password box
            Keys.onPressed: event => {
                if (event.key === Qt.Key_Left && !text) {
                    userList.decrementCurrentIndex();
                    event.accepted = true
                }
                if (event.key === Qt.Key_Right && !text) {
                    userList.incrementCurrentIndex();
                    event.accepted = true
                }
            }

            Connections {
                target: sddm
                function onLoginFailed() {
                    passwordBox.selectAll()
                    passwordBox.forceActiveFocus()
                }
            }
        }

        PlasmaComponents3.Button {
            id: loginButton
            Accessible.name: i18ndc("plasma-desktop-sddm-theme", "@action:button Accessible name", "Log in")
            Layout.preferredHeight: passwordBox.implicitHeight
            Layout.preferredWidth: text.length === 0 ? loginButton.Layout.preferredHeight : -1

            // filled primary: a circle with an arrow, or a pill with the
            // label when no password is needed
            background: Rectangle {
                radius: loginButton.down ? Ae.Theme.rInner + 4 : height / 2
                color: Ae.Theme.primary
                Behavior on radius { NumberAnimation { duration: Ae.Theme.durShort; easing.type: Easing.OutBack } }
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: -5
                    radius: parent.radius + 5
                    color: "transparent"
                    border.width: 3
                    border.color: Ae.Theme.primary
                    visible: loginButton.visualFocus
                }
            }
            leftPadding: text.length === 0 ? 0 : 22
            rightPadding: text.length === 0 ? 0 : 22
            contentItem: Item {
                implicitWidth: loginButton.text.length === 0 ? 22 : label.implicitWidth
                implicitHeight: 22
                Ae.Sym {
                    anchors.centerIn: parent
                    visible: loginButton.text.length === 0
                    name: root.LayoutMirroring.enabled ? "arrow_back" : "arrow_forward"
                    size: 22
                    weight: 600
                    color: Ae.Theme.primaryFg
                }
                Ae.Label {
                    id: label
                    anchors.centerIn: parent
                    visible: loginButton.text.length > 0
                    text: loginButton.text
                    color: Ae.Theme.primaryFg
                    font.weight: Font.DemiBold
                }
            }

            text: root.showUsernamePrompt || userList.currentItem.needsPassword ? "" : i18nc("@action:button", "Log In")
            onClicked: startLogin()
            Keys.onEnterPressed: clicked()
            Keys.onReturnPressed: clicked()
        }
    }
}
