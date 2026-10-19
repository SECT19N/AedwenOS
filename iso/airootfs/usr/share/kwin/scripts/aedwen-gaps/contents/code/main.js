// AedwenOS window gaps (Desktop design: "WINDOWS"). Every window keeps an
// 8 px gap -- to the screen edges, the floating top bar and its neighbours --
// and keeps its 2 px border, rounded corners and shadow, tiled or maximised.
//
// Tiling: KWin's tiles carry a padding (half between tiles, full against the
// screen edges, see Tile::windowGeometry). Quick tiles (Meta+arrows, edge
// drag) are created with padding 0 and custom tiles with 4, and kwinrc keys
// the custom value per desktop and output UUID, so /etc/xdg can't preset it.
// Set it here on whichever root tile a window lands in.
//
// Maximise: KWin always maximises to the full work area and Aurorae draws
// maximised windows square and borderless. A full maximise is turned into a
// "pseudo-maximise" instead: the window is restored and placed in the work
// area inset by GAP, so it is never in KWin's maximised state and keeps the
// normal frame. Maximising a pseudo-maximised window again (double-click,
// the button, Meta+PgUp) restores its previous geometry.
//
// Debug: journalctl -b -f | grep aedwen-gaps

const GAP = 8;
// KWin::MaximizeMode
const MAXIMIZE_RESTORE = 0;
const MAXIMIZE_FULL = 3;

// pseudo-maximised window -> geometry to restore
const restore = new Map();
// window -> {mode, geometry} captured in maximizedAboutToChange
const pending = new Map();
let busy = false;

function log(msg) {
    console.info("aedwen-gaps: " + msg);
}

function rect(r) {
    return { x: r.x, y: r.y, width: r.width, height: r.height };
}

function insetArea(window) {
    const a = workspace.clientArea(KWin.MaximizeArea, window);
    return { x: a.x + GAP, y: a.y + GAP, width: a.width - 2 * GAP, height: a.height - 2 * GAP };
}

function managed(window) {
    return window.normalWindow && window.maximizable && window.resizeable
        && !window.fullScreen && !window.noBorder;
}

// --- tiles ---

function padTile(tile) {
    if (!tile)
        return;
    while (tile.parent)
        tile = tile.parent;
    // setPadding recurses into the children and re-fits their windows
    if (tile.padding !== GAP)
        tile.padding = GAP;
}

function padScreens() {
    for (const output of workspace.screens) {
        for (const desktop of workspace.desktops)
            padTile(workspace.rootTile(output, desktop));
    }
}

// --- maximise ---

function pseudoMaximize(window, from) {
    busy = true;
    window.setMaximize(false, false);
    window.frameGeometry = insetArea(window);
    busy = false;
    restore.set(window, from);
}

function unPseudoMaximize(window) {
    const from = restore.get(window);
    restore.delete(window);
    busy = true;
    if (window.maximizeMode !== MAXIMIZE_RESTORE)
        window.setMaximize(false, false);
    if (from)
        window.frameGeometry = from;
    busy = false;
}

function onAboutToChange(window, mode) {
    if (busy)
        return;
    pending.set(window, { mode: mode, geometry: rect(window.frameGeometry) });
}

function onMaximizedChanged(window) {
    if (busy)
        return;
    const p = pending.get(window);
    pending.delete(window);
    if (!p || !managed(window) || window.maximizeMode !== MAXIMIZE_FULL)
        return;
    if (restore.has(window))
        unPseudoMaximize(window);
    else
        pseudoMaximize(window, p.geometry);
}

// Re-fit pseudo-maximised windows when the work area changes (panels,
// screens, resolution).
function refit() {
    for (const window of restore.keys()) {
        busy = true;
        window.frameGeometry = insetArea(window);
        busy = false;
    }
}

function setup(window) {
    if (!window.normalWindow)
        return;
    window.maximizedAboutToChange.connect(mode => onAboutToChange(window, mode));
    window.maximizedChanged.connect(() => onMaximizedChanged(window));
    // the user moved, resized or tiled it: no longer pseudo-maximised
    window.interactiveMoveResizeStarted.connect(() => restore.delete(window));
    window.tileChanged.connect(tile => {
        if (tile)
            restore.delete(window);
        padTile(tile);
    });
    window.outputChanged.connect(() => {
        if (restore.has(window)) {
            busy = true;
            window.frameGeometry = insetArea(window);
            busy = false;
        }
    });
    padTile(window.tile);
    // Apps that remember being maximised map already maximised, before
    // these handlers exist; there's no previous geometry, so restore to a
    // centred 70 % of the work area.
    if (managed(window) && window.maximizeMode === MAXIMIZE_FULL) {
        const a = workspace.clientArea(KWin.MaximizeArea, window);
        const w = Math.round(a.width * 0.7), h = Math.round(a.height * 0.7);
        pseudoMaximize(window, { x: a.x + Math.round((a.width - w) / 2),
                                 y: a.y + Math.round((a.height - h) / 2), width: w, height: h });
    }
}

workspace.windowAdded.connect(setup);
workspace.windowRemoved.connect(window => {
    restore.delete(window);
    pending.delete(window);
});
workspace.screensChanged.connect(() => { padScreens(); refit(); });
workspace.desktopsChanged.connect(padScreens);
workspace.virtualScreenGeometryChanged.connect(refit);

padScreens();
for (const window of workspace.windowList())
    setup(window);
log("loaded, gap " + GAP + " px");
