# Sourced by startplasma before the session starts (and synced into the
# systemd user environment, so plasmashell.service sees it too). Puts the
# AedwenOS overrides of Plasma QML modules ahead of the system import path.
# Today that is only org.kde.plasma.workspace.osd (the on-screen display);
# see /usr/share/aedwen/qml/org/kde/plasma/workspace/osd/qmldir.
export QML_IMPORT_PATH="/usr/share/aedwen/qml${QML_IMPORT_PATH:+:$QML_IMPORT_PATH}"
