// AedwenOS default desktop layout.
// A floating top bar (launcher, tray, clock) and a floating icon dock
// (pinned/running apps), matching the "Desktop - Material 3" section of the
// AedwenOS System Surfaces design. Modelled directly on the stock
// org.kde.plasma.desktop.defaultPanel layout-template script shipped by
// plasma-desktop (same Panel scripting API: height/location/floating/
// alignment/addWidget), not a from-scratch guess at the format.

var desktopsArray = desktopsForActivity(currentActivity());
for (var j = 0; j < desktopsArray.length; j++) {
    desktopsArray[j].wallpaperPlugin = 'org.kde.image';
}

// ---- top bar --------------------------------------------------------------
var topBar = new Panel;
topBar.location = "top";
topBar.height = 44;
topBar.floating = true;

topBar.addWidget("org.kde.plasma.kickoff");
topBar.addWidget("org.kde.plasma.panelspacer");
topBar.addWidget("org.kde.plasma.systemtray");
topBar.addWidget("org.kde.plasma.digitalclock");

// ---- bottom dock ------------------------------------------------------------
var dock = new Panel;
dock.location = "bottom";
dock.height = 58;
dock.floating = true;
dock.alignment = "center";

dock.addWidget("org.kde.plasma.icontasks");
