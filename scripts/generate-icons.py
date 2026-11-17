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

Symbolic icons (the panel, toolbar, menu and status glyphs) are Material
Symbols Rounded: 16px at FILL 0 / opsz 20 and 22px at FILL 0 / opsz 24, as
recolourable KDE symbolic SVGs (fill currentColor, ColorScheme-Text class).
SYMBOLIC below maps KDE icon names to Material Symbols; the outlines are in
scripts/icon_symbolic_glyphs.json.

Everything else the theme doesn't draw falls through to Breeze
(`Inherits=breeze-dark,breeze`).

The glyph outlines live in scripts/icon_glyphs.json so this script needs
nothing beyond the Python standard library (it also runs on the user's
machine, installed as /usr/lib/aedwen/generate-icons.py by build.sh, from
aedwen-icons). To refresh that file after adding an icon to GLYPHS below,
run it once with --extract-glyphs against the module's font (apps, places);
for the symbolics use --extract-symbolic with the full variable font
(MaterialSymbolsRounded[FILL,GRAD,opsz,wght].ttf, which has the opsz axis).
Both need fonttools:

    scripts/generate-icons.py --extract-glyphs \\
        iso/airootfs/usr/lib/qt6/qml/org/aedwen/ui/fonts/MaterialSymbolsRounded.ttf
    scripts/generate-icons.py --extract-symbolic 'MaterialSymbolsRounded[FILL,GRAD,opsz,wght].ttf'

Usage:
    scripts/generate-icons.py --all-static          # the themes the ISO ships
    scripts/generate-icons.py [--seed violet | --accent '#rrggbb']
                              [--mode themed|colour] [--variant expressive|baseline]
                              [--light] [--name Aedwen-Icons] [--out DIR]
                              [--no-symbolic]   # inherit Aedwen-Icons' symbolics instead
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
SYMBOLIC_FILE = os.path.join(HERE, "icon_symbolic_glyphs.json")
ICONS = "iso/airootfs/usr/share/icons"
STATIC_NAME = "Aedwen-Icons"

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
    ("Browser", "public", 30, ["internet-web-browser", "web-browser", "firefox", "org.mozilla.firefox", "chromium", "zen-browser", "zen"]),
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
    # the rest of what the ISO ships (appended: the order drives the shape / tone cycle)
    ("Archives", "folder_zip", 40, ["ark", "org.kde.ark"]),
    ("Screenshots", "screenshot_region", 200, ["spectacle", "org.kde.spectacle"]),
    ("Documents", "menu_book", 20, ["okular", "org.kde.okular"]),
    ("Find files", "manage_search", 230, ["kfind", "org.kde.kfind"]),
    ("Disk usage", "donut_large", 100, ["filelight", "org.kde.filelight"]),
    ("System info", "info", 240, ["kinfocenter", "org.kde.kinfocenter", "hwinfo"]),
    ("System monitor", "monitoring", 160, ["plasma-systemmonitor", "org.kde.plasma-systemmonitor",
                                           "utilities-system-monitor", "ksysguard"]),
    ("Partitions", "hard_drive", 55, ["partitionmanager", "org.kde.partitionmanager"]),
    ("Wallet", "account_balance_wallet", 125, ["kwalletmanager", "kwalletmanager5",
                                               "org.kde.kwalletmanager5", "org.kde.kwalletmanager"]),
    ("Printers", "print", 280, ["printer", "org.kde.PrintQueue", "preferences-devices-printer"]),
    ("Bluetooth", "bluetooth", 255, ["bluedevil", "preferences-system-bluetooth"]),
    ("Phone", "smartphone", 170, ["kdeconnect", "org.kde.kdeconnect.app", "org.kde.kdeconnect.sms"]),
    ("Text", "draft", 300, ["kwrite", "org.kde.kwrite"]),
    ("Appearance", "palette", 330, ["preferences-desktop-color", "preferences-desktop-theme",
                                    "preferences-desktop-theme-global"]),
    ("Search", "search", 220, ["search", "system-search", "org.aedwen.search"]),
    ("Welcome", "waving_hand", 75, ["aedwenos", "org.aedwen.welcome", "start-here", "distributor-logo"]),
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
    ("delete", ["user-trash", "folder-trash", "trash-empty"]),
    ("delete_sweep", ["user-trash-full", "trash-full"]),
    ("history", ["folder-recent", "folder-open-recent"]),
    ("lan", ["folder-network", "network-workgroup", "network-server", "folder-samba"]),
    ("lock", ["folder-locked", "folder-encrypted"]),
    (None, ["folder", "inode-directory"]),
]

# drives and media in the Dolphin sidebar: the design's device icons, as tiles
# (symbol, icon names)
DEVICES = [
    ("hard_drive", ["drive-harddisk", "drive-harddisk-root", "drive-harddisk-solidstate",
                    "drive-multidisk", "drive-partition", "drive-multipartition"]),
    ("lock", ["drive-harddisk-encrypted", "drive-partition-encrypted"]),
    ("usb", ["drive-removable-media-usb", "drive-removable-media-usb-pendrive",
             "drive-harddisk-usb", "media-flash-memory-stick"]),
    ("sd_card", ["media-flash-sd-mmc", "media-flash", "media-flash-smart-media",
                 "drive-removable-media"]),
    ("album", ["drive-optical", "media-optical", "media-optical-dvd", "media-optical-cd-audio",
               "media-optical-data", "media-optical-blu-ray", "media-optical-recordable"]),
    ("computer", ["computer", "computer-laptop"]),
    ("smartphone", ["smartphone", "phone"]),
    ("lan", ["network-server-database"]),
]

GLYPHS = sorted({a[1] for a in APPS} | {p[0] for p in PLACES if p[0]} | {d[0] for d in DEVICES})

# KDE / freedesktop icon name (without -symbolic) -> Material Symbol, by
# context. Names Breeze ships; anything not listed falls through to Breeze.
SYMBOLIC = {
    "actions": {
        "edit-copy": "content_copy", "edit-cut": "content_cut", "edit-paste": "content_paste",
        "edit-delete": "delete", "edit-undo": "undo", "edit-redo": "redo",
        "edit-find": "search", "edit-clear": "backspace", "edit-select-all": "select_all",
        "edit-rename": "drive_file_rename_outline", "document-new": "note_add",
        "document-open": "folder_open", "document-save": "save", "document-save-as": "save_as",
        "document-print": "print", "document-edit": "edit", "document-properties": "info",
        "go-previous": "arrow_back", "go-next": "arrow_forward", "go-up": "arrow_upward",
        "go-down": "arrow_downward", "go-home": "home",
        "list-add": "add", "list-remove": "remove",
        "window-close": "close", "window-minimize": "minimize", "window-maximize": "crop_square",
        "window-restore": "filter_none", "window-new": "open_in_new",
        "view-refresh": "refresh", "view-fullscreen": "fullscreen", "view-restore": "fullscreen_exit",
        "view-list-details": "view_list", "view-list-icons": "grid_view", "view-sort": "sort",
        "view-filter": "filter_list", "view-visible": "visibility", "view-hidden": "visibility_off",
        "zoom-in": "zoom_in", "zoom-out": "zoom_out", "zoom-fit-best": "fit_screen",
        "application-exit": "exit_to_app", "application-menu": "menu", "open-menu": "menu",
        "overflow-menu": "more_vert", "folder-new": "create_new_folder",
        "bookmark-new": "bookmark_add", "bookmarks": "bookmarks", "starred": "star",
        "media-playback-start": "play_arrow", "media-playback-pause": "pause",
        "media-playback-stop": "stop", "media-skip-forward": "skip_next",
        "media-skip-backward": "skip_previous", "media-seek-forward": "fast_forward",
        "media-seek-backward": "fast_rewind", "media-record": "fiber_manual_record",
        "media-eject": "eject", "media-playlist-repeat": "repeat",
        "media-playlist-shuffle": "shuffle", "mail-send": "send", "mail-reply-sender": "reply",
        "mail-forward": "forward", "mail-attachment": "attach_file", "configure": "settings",
        "dialog-ok": "check", "dialog-cancel": "cancel", "dialog-close": "close",
        "help-about": "info", "help-contents": "help",
        "system-lock-screen": "lock", "system-log-out": "logout", "system-reboot": "restart_alt",
        "system-shutdown": "power_settings_new", "system-suspend": "bedtime",
        "system-search": "search", "archive-extract": "unarchive", "download": "download",
        "emblem-favorite": "favorite", "object-locked": "lock", "object-unlocked": "lock_open",
        "sync-synchronizing": "sync",
    },
    "status": {
        "audio-volume-high": "volume_up", "audio-volume-medium": "volume_down",
        "audio-volume-low": "volume_mute", "audio-volume-muted": "volume_off",
        "microphone-sensitivity-high": "mic", "microphone-sensitivity-muted": "mic_off",
        "network-wireless": "wifi", "network-wireless-offline": "wifi_off",
        "network-wired": "lan", "bluetooth": "bluetooth", "bluetooth-active": "bluetooth_connected",
        "bluetooth-disabled": "bluetooth_disabled", "battery": "battery_5_bar",
        "battery-full": "battery_full", "battery-caution": "battery_alert",
        "battery-low": "battery_alert", "battery-charging": "battery_charging_full",
        "notification-active": "notifications_active", "notification-inactive": "notifications_off",
        "notifications": "notifications", "notifications-disabled": "notifications_off",
        "dialog-information": "info", "dialog-warning": "warning", "dialog-error": "error",
        "dialog-question": "help", "dialog-password": "lock",
        "user-available": "check_circle", "user-away": "schedule", "user-busy": "do_not_disturb_on",
        "weather-clear": "light_mode", "weather-clear-night": "dark_mode",
        "weather-few-clouds": "partly_cloudy_day", "weather-overcast": "cloud",
        "weather-showers": "rainy", "weather-snow": "weather_snowy", "weather-storm": "thunderstorm",
        "display-brightness": "brightness_medium", "night-light": "nightlight",
    },
    "devices": {
        "computer": "computer", "computer-laptop": "laptop", "phone": "smartphone",
        "drive-harddisk": "hard_drive", "drive-removable-media": "usb",
        "drive-optical": "album", "camera-photo": "photo_camera", "camera-video": "videocam",
        "input-keyboard": "keyboard", "input-mouse": "mouse", "input-gaming": "sports_esports",
        "printer": "print", "scanner": "scanner", "audio-headphones": "headphones",
        "audio-headset": "headset_mic", "audio-speakers": "speaker", "video-display": "monitor",
        "media-flash-sd-mmc": "sd_card",
    },
    "places": {
        "folder": "folder", "folder-open": "folder_open", "user-home": "home",
        "user-desktop": "desktop_windows", "user-trash": "delete", "user-trash-full": "delete_forever",
        "folder-documents": "description", "folder-download": "download",
        "folder-music": "music_note", "folder-pictures": "image", "folder-videos": "movie",
        "folder-cloud": "cloud", "folder-favorites": "folder_special", "folder-recent": "history",
        "folder-network": "lan", "network-server": "dns",
    },
}
SYMBOLIC_SIZES = {16: 20, 22: 24}  # px -> opsz
SYMBOLIC_GLYPHS = sorted({g for ctx in SYMBOLIC.values() for g in ctx.values()})


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


def extract_symbolic(font_path):
    from fontTools.pens.svgPathPen import SVGPathPen
    from fontTools.pens.transformPen import TransformPen
    from fontTools.ttLib import TTFont
    from fontTools.varLib.instancer import instantiateVariableFont

    out = {}
    for px, opsz in SYMBOLIC_SIZES.items():
        font = instantiateVariableFont(TTFont(font_path), {"FILL": 0, "GRAD": 0, "opsz": opsz, "wght": 400})
        cmap = font.getBestCmap()
        ligas = {}
        for lookup in font["GSUB"].table.LookupList.Lookup:
            for st in lookup.SubTable:
                st = getattr(st, "ExtSubTable", st)
                for first, ligs in getattr(st, "ligatures", {}).items():
                    for lig in ligs:
                        ligas.setdefault(first, []).append((lig.Component, lig.LigGlyph))
        gs = font.getGlyphSet()
        for name in SYMBOLIC_GLYPHS:
            chars = [cmap[ord(c)] for c in name]
            glyph = next((r for comps, r in ligas.get(chars[0], []) if list(comps) == chars[1:]), None)
            if glyph is None:
                sys.exit(f"no ligature for {name!r} in the font")
            pen = SVGPathPen(gs, ntos=lambda v: ("%.1f" % v).rstrip("0").rstrip("."))
            gs[glyph].draw(TransformPen(pen, (1, 0, 0, -1, 0, UPM)))
            out.setdefault(name, {})[str(px)] = pen.getCommands()
    with open(SYMBOLIC_FILE, "w") as f:
        json.dump(out, f, indent=0, sort_keys=True)
        f.write("\n")
    print(f"Wrote {len(out)} symbolic glyphs x {len(SYMBOLIC_SIZES)} sizes to {SYMBOLIC_FILE}")


def load_symbolic():
    try:
        with open(SYMBOLIC_FILE) as f:
            glyphs = json.load(f)
    except OSError:
        sys.exit(f"{SYMBOLIC_FILE} missing; run --extract-symbolic first")
    missing = [g for g in SYMBOLIC_GLYPHS if g not in glyphs]
    if missing:
        sys.exit(f"icon_symbolic_glyphs.json lacks {', '.join(missing)}; rerun --extract-symbolic")
    return glyphs


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


def symbolic_svg(px, path):
    """A KDE symbolic icon: recoloured at runtime from the ColorScheme-Text class."""
    s = px / UPM
    return (
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{px}" height="{px}" viewBox="0 0 {px} {px}">'
        '<defs><style type="text/css" id="current-color-scheme">'
        ".ColorScheme-Text{color:#232629}</style></defs>"
        f'<path class="ColorScheme-Text" fill="currentColor" transform="scale({s:.6f})" d="{path}"/></svg>\n'
    )


def write_symbolic(out):
    glyphs = load_symbolic()
    count = 0
    for context, names in SYMBOLIC.items():
        for px in SYMBOLIC_SIZES:
            d = os.path.join(out, context, str(px))
            os.makedirs(d, exist_ok=True)
            for old in os.listdir(d):
                os.remove(os.path.join(d, old))
            for name, glyph in names.items():
                with open(os.path.join(d, name + "-symbolic.svg"), "w") as fh:
                    fh.write(symbolic_svg(px, glyphs[glyph][str(px)]))
                count += 1
    return count // len(SYMBOLIC_SIZES)


def link(target, name):
    if os.path.lexists(name):
        os.remove(name)
    os.symlink(target, name)


def build_theme(out, name, seed_hex, mode, variant, dark, symbolic=True):
    glyphs = load_glyphs()
    hue = srgb_hex_to_oklch(seed_hex)[2]
    expressive = variant == "expressive"
    pal = palette(hue, dark, expressive)

    apps_dir = os.path.join(out, "scalable", "apps")
    places_dir = os.path.join(out, "scalable", "places")
    devices_dir = os.path.join(out, "scalable", "devices")
    for d in (apps_dir, places_dir, devices_dir):
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

    for i, (glyph, names) in enumerate(DEVICES):
        file = names[0] + ".svg"
        with open(os.path.join(devices_dir, file), "w") as fh:
            fh.write(app_icon(i, glyph, 250, glyphs, pal, "themed", dark, expressive))
        for alias in names[1:]:
            link(file, os.path.join(devices_dir, alias + ".svg"))

    inherits = "breeze-dark,breeze" if dark else "breeze,breeze-dark"
    dirs = ["scalable/apps", "scalable/places", "scalable/devices"]
    sections = ""
    nsym = 0
    if symbolic:
        nsym = write_symbolic(out)
        for context in SYMBOLIC:
            for px in SYMBOLIC_SIZES:
                dirs.append(f"{context}/{px}")
                sections += (f"\n[{context}/{px}]\nSize={px}\nContext={context.capitalize()}\n"
                             "Type=Fixed\n")
    else:
        # the symbolics are colourless: a seed-tinted copy shares the shipped ones
        inherits = f"{STATIC_NAME}," + inherits
    with open(os.path.join(out, "index.theme"), "w") as fh:
        fh.write(f"""[Icon Theme]
Name={name}
Comment=AedwenOS app icons · {'Themed' if mode == 'themed' else 'Full colour'}, {variant}, {'dark' if dark else 'light'} (generated by generate-icons.py)
Inherits={inherits}
Directories={",".join(dirs)}

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

[scalable/devices]
Size=64
MinSize=16
MaxSize=512
Context=Devices
Type=Scalable
{sections}""")
    print(f"Wrote {name}: {len(APPS)} apps + {len(PLACES)} places + {len(DEVICES)} devices + {nsym} symbolic to {out}")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--all-static", action="store_true",
                    help=f"build the themes the ISO ships into {ICONS}")
    ap.add_argument("--extract-glyphs", metavar="FONT",
                    help="rebuild icon_glyphs.json from Material Symbols Rounded (needs fonttools)")
    ap.add_argument("--extract-symbolic", metavar="FONT",
                    help="rebuild icon_symbolic_glyphs.json from the full Material Symbols Rounded variable font")
    ap.add_argument("--no-symbolic", action="store_true",
                    help="don't write symbolic icons; inherit the shipped Aedwen-Icons' instead")
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

    if args.extract_symbolic:
        extract_symbolic(args.extract_symbolic)
        return

    seed_hex = args.accent or SEED_HEX[args.seed]
    if args.all_static:
        build_theme(os.path.join(ICONS, "Aedwen-Icons"), "Aedwen-Icons",
                    seed_hex, "themed", "expressive", True)
    else:
        build_theme(args.out, args.name, seed_hex, args.mode, args.variant, not args.light,
                    symbolic=not args.no_symbolic)


if __name__ == "__main__":
    main()
