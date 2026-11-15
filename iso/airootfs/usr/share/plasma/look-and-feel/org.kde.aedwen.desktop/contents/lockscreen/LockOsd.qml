/*
    SPDX-FileCopyrightText: 2014 Aleix Pol Gonzalez <aleixpol@blue-systems.com>

    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import org.kde.kirigami as Kirigami
import org.kde.plasma.workspace.osd

Item {
    id: osd

    property alias timeout: osdItem.timeout
    property alias osdValue: osdItem.osdValue
    property alias osdMaxValue: osdItem.osdMaxValue
    property alias icon: osdItem.icon
    property alias showingProgress: osdItem.showingProgress

    objectName: "onScreenDisplay"
    visible: false
    // the AedwenOS OsdItem draws its own pill (usr/share/aedwen/qml/...osd)
    width: osdItem.width
    height: osdItem.height

    Kirigami.Theme.inherit: false
    Kirigami.Theme.colorSet: Kirigami.Theme.Window

    function show() {
        osd.visible = true;
        hideAnimation.restart();
    }

    // avoid leaking ColorScope of lock screen theme into the OSD "popup"
    Item {
        width: osdItem.width
        height: osdItem.height
        anchors.centerIn: parent

        OsdItem {
            id: osdItem
        }
    }

    SequentialAnimation {
        id: hideAnimation
        ScriptAction {
            // prevent opacity layering of ProgressBar.
            script: osd.layer.enabled = true
        }
        // prevent press and hold from flickering
        PauseAnimation { duration: osd.timeout }
        NumberAnimation {
            target: osd
            property: "opacity"
            from: 1
            to: 0
            duration: Kirigami.Units.shortDuration
            easing.type: Easing.InQuad
        }
        ScriptAction {
            script: {
                osd.visible = false;
                osd.opacity = 1;
                osd.icon = "";
                osd.osdValue = 0;
                osd.layer.enabled = false;
            }
        }
    }
}
