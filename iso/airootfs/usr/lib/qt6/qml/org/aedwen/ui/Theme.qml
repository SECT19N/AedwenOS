// Design tokens for every AedwenOS shell surface (AedwenOS System Surfaces
// design), shared by all org.aedwen.* widgets.
//
// Colours are not baked in: they are read live from the active KDE colour
// scheme, so switching scheme (accent, light/dark) restyles the shell at
// once. scripts/generate-colorscheme.py writes the Material 3 roles into the
// KDE colour sets as follows, and this file reads them back:
//
//   surface   View.Background          scLow      Complementary.Background
//   sc        Header.Background        scHigh     Button.Background
//   scHighest Button.BackgroundAlt     primary    Selection.Background
//   primaryFg Selection.Foreground     pc         ForegroundPositive
//   secC      ForegroundVisited        terC       ForegroundNeutral
//   err       ForegroundNegative       fg/fgVariant  Foreground Normal/Inactive
//
// Inside plasmashell Kirigami gets its colours from the Plasma theme, which
// has no Selection set and no alternate backgrounds -- so primary comes from
// the highlight colour (the same in every set) and anything Plasma can't
// provide is derived by mixing. With a non-AedwenOS colour scheme (e.g.
// Breeze), whose "positive" colour is green rather than the primary
// container, pc is derived too. The remaining "on-container" and outline
// roles are always derived.
pragma Singleton
import QtQuick
import org.kde.kirigami as Kirigami

QtObject {
    id: theme

    // --- colour sets, read through objects that don't inherit -----------------
    // (plain QtObjects: Kirigami never resolves colours on a parentless Item)
    property QtObject _view: QtObject {
        Kirigami.Theme.colorSet: Kirigami.Theme.View
        Kirigami.Theme.inherit: false
    }
    property QtObject _header: QtObject {
        Kirigami.Theme.colorSet: Kirigami.Theme.Header
        Kirigami.Theme.inherit: false
    }
    property QtObject _button: QtObject {
        Kirigami.Theme.colorSet: Kirigami.Theme.Button
        Kirigami.Theme.inherit: false
    }
    property QtObject _comp: QtObject {
        Kirigami.Theme.colorSet: Kirigami.Theme.Complementary
        Kirigami.Theme.inherit: false
    }
    // a + (b - a) * t, per channel (alpha from a)
    function mix(a, b, t) {
        return Qt.rgba(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t,
                       a.b + (b.b - a.b) * t, a.a)
    }
    function alpha(c, a) { return Qt.rgba(c.r, c.g, c.b, a) }
    function luma(c) { return 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b }
    function sameHue(a, b) {
        const d = Math.abs(a.hsvHue - b.hsvHue)
        return a.hsvSaturation > 0.15 && Math.min(d, 1 - d) < 0.08
    }

    readonly property color surface: _view.Kirigami.Theme.backgroundColor
    readonly property color scLow: _comp.Kirigami.Theme.backgroundColor
    readonly property color sc: _header.Kirigami.Theme.backgroundColor
    readonly property color scHigh: _button.Kirigami.Theme.backgroundColor
    readonly property color scHighest: Qt.colorEqual(_button.Kirigami.Theme.alternateBackgroundColor, scHigh)
                                       ? mix(scHigh, fg, 0.04) : _button.Kirigami.Theme.alternateBackgroundColor
    readonly property color fg: _view.Kirigami.Theme.textColor
    readonly property color fgVariant: _view.Kirigami.Theme.disabledTextColor
    readonly property color primary: _view.Kirigami.Theme.highlightColor
    readonly property color primaryFg: _view.Kirigami.Theme.highlightedTextColor
    readonly property color pc: sameHue(_view.Kirigami.Theme.positiveTextColor, primary)
                                ? _view.Kirigami.Theme.positiveTextColor
                                : mix(primary, surface, dark ? 0.6 : 0.72)
    readonly property color secC: _view.Kirigami.Theme.visitedLinkColor
    readonly property color terC: _view.Kirigami.Theme.neutralTextColor
    readonly property color err: _view.Kirigami.Theme.negativeTextColor

    readonly property bool dark: luma(surface) < 0.5
    readonly property color pcFg: mix(primary, fg, 0.65)
    readonly property color secCFg: mix(fg, primary, 0.12)
    readonly property color terCFg: mix(fg, terC, 0.15)
    readonly property color errC: mix(surface, err, dark ? 0.35 : 0.25)
    readonly property color errCFg: mix(fg, err, 0.25)
    // High contrast (Appearance > Contrast = High): full-strength outlines,
    // 2px borders, solid hover/press fills, no translucency, heavier text.
    readonly property bool highContrast: _config && _config.contrast === "high"
    readonly property int outlineW: highContrast ? 2 : 1
    readonly property color outline: highContrast ? fg : mix(fg, surface, 0.45)
    readonly property color outlineV: highContrast ? fg : mix(fg, surface, 0.78)
    // 8% on-surface state layer (hover) and 12% (pressed)
    readonly property color state: alpha(fg, 0.08)
    readonly property color statePressed: alpha(fg, 0.12)
    // StateLayer opacities; high contrast uses solid fills instead
    readonly property real hoverOpacity: highContrast ? 0.24 : 0.08
    readonly property real pressOpacity: highContrast ? 0.4 : 0.12

    // Panel / popup fill for the "light acrylic" look: the Plasma theme
    // blurs what's behind, this keeps it mostly opaque.
    readonly property real acrylic: highContrast ? 1.0 : 0.86

    // --- variant -------------------------------------------------------------
    // "expressive" (shipped default) or "baseline" (plain Material 3), from
    // kdeglobals [AedwenOS] Variant via the optional org.aedwen.config plugin
    // (package aedwen-tools, Appearance settings). The plugin is created
    // dynamically: Theme also loads in SDDM, the lock screen and KSplash, and
    // a static import of a missing module would be a hard error there.
    property QtObject _config: {
        try {
            return Qt.createQmlObject('import org.aedwen.config; AedwenConfig {}', theme, "AedwenConfig")
        } catch (e) {
            return null
        }
    }
    readonly property string variant: _config && _config.variant === "baseline" ? "baseline" : "expressive"
    readonly property bool expressive: variant !== "baseline"

    // --- shape (Desktop design token tables: baseline | expressive) ------------
    readonly property int rWin: expressive ? 16 : 12
    readonly property int rInner: expressive ? 10 : 8
    readonly property int rPop: expressive ? 32 : 28
    readonly property int rCard: expressive ? 20 : 16
    readonly property int rTile: 12      // app icon tiles (design: 11-12px at 40px)
    readonly property int rBar: expressive ? 999 : 16
    readonly property int rItem: 999     // list rows, nav items, search results
    readonly property int rPill: 999
    readonly property int sliderH: expressive ? 40 : 16
    // The Desktop design's Expressive icon shapes (EXPR_SHAPES), as corner
    // radii [topLeft, topRight, bottomRight, bottomLeft] for a `size` px
    // tile; list surfaces cycle through them (notifications: i * 3 + 1).
    // Baseline tiles are circles.
    readonly property var exprShapes: [
        [16, 16, 16, 16], ["50%", "50%", "50%", "50%"], ["50%", "50%", "50%", 14], [14, 14, 14, 14],
        ["50%", "50%", 16, 16], ["50%", "50%", "50%", "50%"], [16, 16, "50%", "50%"], ["30%", "30%", "30%", "30%"],
        ["50%", 14, "50%", 14], [14, "50%", 14, "50%"]
    ]
    function exprShape(i, size) {
        const s = expressive ? exprShapes[((i % exprShapes.length) + exprShapes.length) % exprShapes.length]
                             : ["50%", "50%", "50%", "50%"]
        return s.map(v => typeof v === "string" ? size * parseFloat(v) / 100 : v)
    }

    // full-screen scrim behind modal surfaces (search, overview)
    readonly property color scrim: dark ? Qt.rgba(0, 0, 0, 0.36) : Qt.rgba(20 / 255, 20 / 255, 30 / 255, 0.28)

    // --- spacing / sizes -----------------------------------------------------
    readonly property int controlShell: 40    // controls in the shell
    readonly property int controlApp: 36      // controls inside apps
    readonly property int gap: 8

    // --- motion --------------------------------------------------------------
    // Kirigami reports 0 durations when the user turns animations off, so
    // every animation built on these respects "reduce motion".
    readonly property bool animate: Kirigami.Units.longDuration > 0
    readonly property var spring: [0.34, 1.45, 0.55, 1, 1, 1]   // cubic-bezier(.34,1.45,.55,1)
    readonly property var standard: [0.2, 0, 0, 1, 1, 1]
    // shape morphs: spring 420 ms (expressive), standard 300 ms (baseline)
    readonly property int dur: animate ? (expressive ? 420 : 300) : 0
    readonly property var morphEasing: expressive ? spring : standard
    readonly property int durShort: animate ? 180 : 0  // hover, colour
    readonly property int durMed: animate ? 260 : 0

    // --- type ----------------------------------------------------------------
    readonly property string font: Kirigami.Theme.defaultFont.family
    // +100 weight in high contrast (Font.Normal -> Medium, Medium -> DemiBold ...)
    function weight(w) { return highContrast ? Math.min(900, w + 100) : w }
    readonly property string mono: "Roboto Mono"
    property FontLoader _symbols: FontLoader { source: Qt.resolvedUrl("fonts/MaterialSymbolsRounded.ttf") }
    readonly property string symbols: _symbols.name

    readonly property url eagle: Qt.resolvedUrl("images/eagle.svg")
}
