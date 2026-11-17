#!/usr/bin/env python3
"""
Generate the "Aedwen-Icons" icon theme from the app icons in the AedwenOS
System Surfaces design (section 05, "Icons").

Ported from the design's `apps` / `SH` / `hueOf` tables and its tile
renderer: every app icon is a tile whose shape comes from a cycling set of
corner radii (Expressive) or a single rounded square (Baseline), with a
Material Symbol (filled) at 55% of the tile in the middle.

  Themed       tiles take the palette's primary / secondary / tertiary
               container colours in turn (i % 3), so the set is tinted to
               the seed colour.
  Full colour  each app keeps its own hue (hueOf), on the same shapes.

Places are the design's folder: a darker tab behind a primary-container
body with the place's symbol in it, in both modes.

Only the apps and places are drawn here. The theme `Inherits=breeze-dark,
breeze`, so every other icon falls through to Breeze.

The glyph outlines live in scripts/icon_glyphs.json so this script needs
nothing beyond the Python standard library (it also runs on the user's
machine, installed as /usr/lib/aedwen/generate-icons.py by build.sh, from
aedwen-icons). To refresh that file after adding an icon to GLYPHS below,
run it once with --extract-glyphs against the module's font; that needs
fonttools:

    scripts/generate-icons.py --extract-glyphs \\
        iso/airootfs/usr/lib/qt6/qml/org/aedwen/ui/fonts/MaterialSymbolsRounded.ttf

Usage:
    scripts/generate-icons.py --all-static          # the themes the ISO ships
    scripts/generate-icons.py [--seed violet | --accent '#rrggbb']
                              [--mode themed|colour] [--variant expressive|baseline]
                              [--light] [--name Aedwen-Icons] [--out DIR]
"""

import argparse
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from palette_lib import (  # noqa: E402
    SEED_HEX,
    o,
    palette,
    srgb_hex_to_oklch,
)

HERE = os.path.dirname(os.path.abspath(__file__))
GLYPH_FILE = os.path.join(HERE, "icon_glyphs.json")
ICONS = "iso/airootfs/usr/share/icons"

TILE = 56  # design: 56px tile
SYMBOL = 30  # design: 30px glyph in it (~55%)
UPM = 960  # Material Symbols units per em

# Design `SH`: border-radius per app index (top-left, top-right, bottom-right,
# bottom-left), as a fraction of the tile (50% = 0.5) or px (16px = 16/56).
R16 = 16 / TILE
EXPRESSIVE_SHAPES = [
    (0.5, 0.5, 0.5, 0.5),
    (R16, R16, R16, R16),
    (0.5, 0.5, 0.5, R16),
    (0.3, 0.3, 0.3, 0.3),
    (0.5, 0.5, R16, R16),
    (R16, R16, 0.5, 0.5),
]
BASELINE_SHAPE = (R16, R16, R16, R16)

# (design name, symbol, hue for Full colour, icon names it answers to). The
# first name is the file; the rest are symlinks to it.
APPS = [
    ("Files", "folder", 250, ["system-file-manager", "org.kde.dolphin", "dolphin", "file-manager"]),
    ("Browser", "public", 30, ["internet-web-browser", "web-browser", "firefox", "org.mozilla.firefox", "chromium"]),
    ("Terminal", "terminal", 150, ["utilities-terminal", "org.kde.konsole", "konsole"]),
    ("Settings", "settings", 250, ["preferences-system", "systemsettings", "org.kde.systemsettings"]),
    ("Mail", "mail", 210, ["internet-mail", "mail-client", "org.kde.kmail2", "kmail"]),
    ("Music", "music_note", 330, ["multimedia-audio-player", "org.kde.elisa", "elisa"]),
    ("Photos", "photo_library", 80, ["camera-photo", "org.kde.gwenview", "gwenview", "image-viewer"]),
    ("Calendar", "calendar_month", 10, ["office-calendar", "org.kde.korganizer", "korganizer"]),
    ("Editor", "edit_note", 290, ["accessories-text-editor", "org.kde.kate", "kate", "text-editor"]),
    ("Store", "storefront", 185, ["system-software-install", "org.kde.discover", "plasmadiscover", "octopi"]),
    ("Calculator", "calculate", 60, ["accessories-calculator", "org.kde.kcalc", "kcalc"]),
    ("Clock", "schedule", 265, ["clock", "org.kde.kclock", "preferences-system-time"]),
]

# (symbol, icon names); the first is the file. "folder" has no symbol.
PLACES = [
    ("home", ["user-home", "folder-home"]),
    ("description", ["folder-documents"]),
    ("download", ["folder-download", "folder-downloads"]),
    ("image", ["folder-pictures"]),
    ("music_note", ["folder-music"]),
    ("movie", ["folder-videos"]),
    ("desktop_windows", ["user-desktop", "folder-desktop"]),
    ("cloud", ["folder-cloud", "folder-remote"]),
    (None, ["folder", "inode-directory"]),
]

GLYPHS = sorted({a[1] for a in APPS} | {p[0] for p in PLACES if p[0]})


# --- glyph extraction (needs fonttools) ----------------------------------

def extract_glyphs(font_path):
    from fontTools.pens.svgPathPen import SVGPathPen
    from fontTools.pens.transformPen import TransformPen
    from fontTools.ttLib import TTFont
    from fontTools.varLib.instancer import instantiateVariableFont

    font = TTFont(font_path)
    font = instantiateVariableFont(font, {"FILL": 1, "wght": 500})
    order = font.getGlyphOrder()
    cmap = font.getBestCmap()
    ligas = {}  # first glyph -> [(components, result)]
    for lookup in font["GSUB"].table.LookupList.Lookup:
        for st in lookup.SubTable:
            st = getattr(st, "ExtSubTable", st)
            for first, ligs in getattr(st, "ligatures", {}).items():
                for lig in ligs:
                    ligas.setdefault(first, []).append((lig.Component, lig.LigGlyph))

    def glyph_for(name):
        chars = [cmap[ord(c)] for c in name]
        for comps, result in ligas.get(chars[0], []):
            if list(comps) == chars[1:]:
                return result
        sys.exit(f"no ligature for {name!r} in the font")

    gs = font.getGlyphSet()
    out = {}
    for name in GLYPHS:
        pen = SVGPathPen(gs, ntos=lambda v: ("%.1f" % v).rstrip("0").rstrip("."))
        # font units are y-up with the baseline at 0; the icon box is
        # y 0..960 with the baseline at its bottom, so flip into SVG space
        gs[glyph_for(name)].draw(TransformPen(pen, (1, 0, 0, -1, 0, UPM)))
        out[name] = pen.getCommands()
    with open(GLYPH_FILE, "w") as f:
        json.dump(out, f, indent=0, sort_keys=True)
        f.write("\n")
    print(f"Wrote {len(out)} glyphs to {GLYPH_FILE} (order {len(order)} glyphs in font)")


def load_glyphs():
    try:
        with open(GLYPH_FILE) as f:
            glyphs = json.load(f)
    except OSError:
        sys.exit(f"{GLYPH_FILE} missing; run --extract-glyphs first")
    missing = [g for g in GLYPHS if g not in glyphs]
    if missing:
        sys.exit(f"icon_glyphs.json lacks {', '.join(missing)}; rerun --extract-glyphs")
    return glyphs


# --- drawing -------------------------------------------------------------

def f(v):
    return ("%.2f" % v).rstrip("0").rstrip(".")


def round_rect(x, y, w, h, tl, tr, br, bl):
    """Path of a rectangle with circular corners (radii clamped like CSS)."""
    tl, tr, br, bl = (max(0.0, r) for r in (tl, tr, br, bl))
    scale = min(
        1.0,
        *(
            side / total
            for side, total in (
                (w, tl + tr), (w, bl + br), (h, tl + bl), (h, tr + br),
            )
            if total > 0
        ),
    )
    tl, tr, br, bl = (r * scale for r in (tl, tr, br, bl))
    return (
        f"M{f(x + tl)} {f(y)}H{f(x + w - tr)}"
        f"A{f(tr)} {f(tr)} 0 0 1 {f(x + w)} {f(y + tr)}"
        f"V{f(y + h - br)}"
        f"A{f(br)} {f(br)} 0 0 1 {f(x + w - br)} {f(y + h)}"
        f"H{f(x + bl)}"
        f"A{f(bl)} {f(bl)} 0 0 1 {f(x)} {f(y + h - bl)}"
        f"V{f(y + tl)}"
        f"A{f(tl)} {f(tl)} 0 0 1 {f(x + tl)} {f(y)}Z"
    )


def symbol(path, cx, cy, size, fill):
    s = size / UPM
    return (
        f'<path transform="translate({f(cx - size / 2)} {f(cy - size / 2)}) '
        f'scale({s:.6f})" fill="{fill}" d="{path}"/>'
    )


def svg(w, h, body):
    return (
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" '
        f'viewBox="0 0 {w} {h}">{body}</svg>\n'
    )


def darken(hex_color, k):
    """CSS filter: brightness(k) on an sRGB hex colour."""
    h = hex_color.lstrip("#")
    return "#" + "".join(
        "{:02x}".format(min(255, round(int(h[i : i + 2], 16) * k))) for i in (0, 2, 4)
    )


def app_icon(i, glyph, hue, glyphs, pal, mode, dark, expressive):
    if mode == "colour":
        bg = o(0.4, 0.12, hue) if dark else o(0.88, 0.08, hue)
        fg = o(0.93, 0.06, hue) if dark else o(0.32, 0.12, hue)
    else:
        bg, fg = [
            ("pc", "on-pc"), ("sec-c", "on-sec-c"), ("ter-c", "on-ter-c")
        ][i % 3]
        bg, fg = pal[bg], pal[fg]
    radii = EXPRESSIVE_SHAPES[i % len(EXPRESSIVE_SHAPES)] if expressive else BASELINE_SHAPE
    r = [x * TILE for x in radii]
    body = (
        f'<path fill="{bg}" d="{round_rect(0, 0, TILE, TILE, *r)}"/>'
        + symbol(glyphs[glyph], TILE / 2, TILE / 2, SYMBOL, fg)
    )
    return svg(TILE, TILE, body)


def place_icon(glyph, glyphs, pal):
    """The design's 60x48 folder, centred in a 60x60 icon."""
    bg, fg = pal["pc"], pal["on-pc"]
    y0 = 6  # centre the 48px-high folder
    body = (
        f'<path fill="{darken(bg, 0.85)}" d="{round_rect(0, y0, 26, 14, 6, 6, 0, 0)}"/>'
        f'<path fill="{bg}" d="{round_rect(0, y0 + 6, 60, 42, 4, 10, 10, 10)}"/>'
    )
    if glyph:
        body += symbol(glyphs[glyph], 30, y0 + 6 + 21, 20, fg)
    return svg(60, 60, body)


def link(target, name):
    if os.path.lexists(name):
        os.remove(name)
    os.symlink(target, name)


def build_theme(out, name, seed_hex, mode, variant, dark):
    glyphs = load_glyphs()
    hue = srgb_hex_to_oklch(seed_hex)[2]
    expressive = variant == "expressive"
    pal = palette(hue, dark, expressive)

    apps_dir = os.path.join(out, "scalable", "apps")
    places_dir = os.path.join(out, "scalable", "places")
    for d in (apps_dir, places_dir):
        os.makedirs(d, exist_ok=True)
        for old in os.listdir(d):
            os.remove(os.path.join(d, old))

    for i, (_, glyph, app_hue, names) in enumerate(APPS):
        file = names[0] + ".svg"
        with open(os.path.join(apps_dir, file), "w") as fh:
            fh.write(app_icon(i, glyph, app_hue, glyphs, pal, mode, dark, expressive))
        for alias in names[1:]:
            link(file, os.path.join(apps_dir, alias + ".svg"))

    for glyph, names in PLACES:
        file = names[0] + ".svg"
        with open(os.path.join(places_dir, file), "w") as fh:
            fh.write(place_icon(glyph, glyphs, pal))
        for alias in names[1:]:
            link(file, os.path.join(places_dir, alias + ".svg"))

    inherits = "breeze-dark,breeze" if dark else "breeze,breeze-dark"
    with open(os.path.join(out, "index.theme"), "w") as fh:
        fh.write(f"""[Icon Theme]
Name={name}
Comment=AedwenOS app icons · {'Themed' if mode == 'themed' else 'Full colour'}, {variant}, {'dark' if dark else 'light'} (generated by generate-icons.py)
Inherits={inherits}
Directories=scalable/apps,scalable/places

[scalable/apps]
Size=64
MinSize=16
MaxSize=512
Context=Applications
Type=Scalable

[scalable/places]
Size=64
MinSize=16
MaxSize=512
Context=Places
Type=Scalable
""")
    print(f"Wrote {name}: {len(APPS)} apps + {len(PLACES)} places to {out}")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--all-static", action="store_true",
                    help=f"build the themes the ISO ships into {ICONS}")
    ap.add_argument("--extract-glyphs", metavar="FONT",
                    help="rebuild icon_glyphs.json from Material Symbols Rounded (needs fonttools)")
    ap.add_argument("--out", default=os.path.join(ICONS, "Aedwen-Icons"))
    ap.add_argument("--name", default="Aedwen-Icons", help="theme name (index.theme Name=)")
    ap.add_argument("--seed", default="violet", choices=SEED_HEX.keys())
    ap.add_argument("--accent", help="seed colour as #rrggbb (overrides --seed)")
    ap.add_argument("--mode", default="themed", choices=["themed", "colour"])
    ap.add_argument("--variant", default="expressive", choices=["expressive", "baseline"])
    ap.add_argument("--light", action="store_true")
    args = ap.parse_args()

    if args.extract_glyphs:
        extract_glyphs(args.extract_glyphs)
        return

    seed_hex = args.accent or SEED_HEX[args.seed]
    if args.all_static:
        build_theme(os.path.join(ICONS, "Aedwen-Icons"), "Aedwen-Icons",
                    seed_hex, "themed", "expressive", True)
    else:
        build_theme(args.out, args.name, seed_hex, args.mode, args.variant, not args.light)


if __name__ == "__main__":
    main()
