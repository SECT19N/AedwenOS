// AedwenOS default desktop layout (AedwenOS Desktop design):
//
//   top bar  launcher · workspace dots · app name + global menu ·
//            (centre) date and time · search · tray · quick settings · bell
//   dock     pinned and running apps, fitted to its content, centred,
//            hiding when a window would cover it ("dodge windows")
//
// Uses the Plasma panel scripting API (height/location/floating/alignment/
// lengthMode/hiding/addWidget), as in plasma-desktop's own defaultPanel
// layout template. The org.aedwen.* widgets are in
// /usr/share/plasma/plasmoids, built on the org.aedwen.ui QML module.

var desktopsArray = desktopsForActivity(currentActivity());
for (var j = 0; j < desktopsArray.length; j++) {
    desktopsArray[j].wallpaperPlugin = 'org.kde.image';
}

// ---- top bar --------------------------------------------------------------
var topBar = new Panel;
topBar.location = "top";
topBar.height = 44;
topBar.floating = true;
topBar.opacity = "translucent";

topBar.addWidget("org.aedwen.launcher");
topBar.addWidget("org.aedwen.workspaces");
topBar.addWidget("org.aedwen.appname");
topBar.addWidget("org.kde.plasma.appmenu");
topBar.addWidget("org.kde.plasma.panelspacer");
topBar.addWidget("org.aedwen.clock");
topBar.addWidget("org.kde.plasma.panelspacer");
topBar.addWidget("org.aedwen.search");

// The tray keeps app status icons (clipboard, KDE Connect, updates, ...).
// Network, volume, battery, Bluetooth and brightness live in Quick Settings
// and notifications in the bell, so KDE's own applets for those stay loaded
// (notification pop-ups, media keys and OSDs come from them) but hidden.
// (In Plasma 6 the tray is itself a containment, so its item lists are in
// the widget's own [General] config.)
var systray = topBar.addWidget("org.kde.plasma.systemtray");
systray.currentConfigGroup = ["General"];
systray.writeConfig("hiddenItems", [
    "org.kde.plasma.notifications",
    "org.kde.plasma.networkmanagement",
    "org.kde.plasma.volume",
    "org.kde.plasma.battery",
    "org.kde.plasma.bluetooth",
    "org.kde.plasma.brightness",
]);

topBar.addWidget("org.aedwen.quicksettings");
topBar.addWidget("org.aedwen.notifications");

// ---- dock -----------------------------------------------------------------
var dock = new Panel;
dock.location = "bottom";
dock.height = 66;
dock.floating = true;
dock.alignment = "center";
dock.lengthMode = "fit";
dock.hiding = "dodgewindows";
dock.opacity = "translucent";

var dockApps = dock.addWidget("org.aedwen.dock");
dockApps.currentConfigGroup = ["General"];
// Pins that aren't installed are skipped by the dock.
dockApps.writeConfig("launchers", [
    "applications:org.kde.dolphin.desktop",
    "applications:zen.desktop",
    "applications:org.kde.konsole.desktop",
    "applications:org.kde.kate.desktop",
    "applications:octopi.desktop",
    "applications:systemsettings.desktop",
]);
