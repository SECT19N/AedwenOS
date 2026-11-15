#!/usr/bin/env python3
"""
Generate the AedwenOS window decorations (title bars) as Aurorae themes.

FALLBACK ONLY: the default decoration is now the C++ one in
packages/aedwen-decoration (kwinrc library=org.kde.aedwen), which can round
all four corners. These themes stay installed for anyone who picks them in
System Settings; keep the two in step when the design changes.

The themes follow the window chrome in the AedwenOS Desktop design ("WINDOWS") and
System Surfaces §02:

  - window corners at the variant's r-win (Expressive 16, baseline 12)
  - a 48 px title bar in the same colour as the window body: app icon, the
    title (14 px semibold; dimmed when unfocused), and three 32 px round
    buttons -- minimise, maximise/restore, close
  - buttons sit on surface-container-highest; on hover/press they fill with a
    primary-tinted container (close: the error container) and, in the
    Expressive variant, turn from a circle into a rounded square (ctl-hr)
  - a 2 px border, primary at 65% when focused, a faint outline when not
  - a soft drop shadow (design: 0 12px 40px rgba(0,0,0,.28))

Fills use KDE colour-scheme classes (ColorScheme-Background, -Highlight,
-ButtonBackground, -NegativeText, -Text), so the frame follows the active
colour scheme and accent, like the Plasma theme. Aurorae takes the title
text colour only from the rc file, so each variant is written twice, for
dark and light schemes:

  usr/share/aurorae/themes/AedwenOS-{Dark,Light}             (Expressive)
  usr/share/aurorae/themes/AedwenOS-Baseline-{Dark,Light}    (stock M3)

Not possible with Aurorae (later edition, needs a C++ decoration): the
animated circle->square morph (Aurorae swaps button states, it can't
animate shape), rounded *bottom* window corners (KWin only clips windows to
a radius for decorations that declare one through the C++ API, so app
content would poke out; the bottom corners are kept small), and the
snap-layouts flyout on the maximise button.

Usage:
    scripts/generate-aurorae-theme.py [--out DIR]

Pure stdlib (the shadow is rendered here and embedded as PNG).
"""

import argparse
import base64
import math
import os
import struct
import sys
import zlib

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from palette_lib import DEFAULT_SEED, SEEDS, VARIANTS, palette, shapes  # noqa: E402

OUT = "iso/airootfs/usr/share/aurorae/themes"

PAD = 24          # shadow padding around the window, all sides
SHADOW_DY = 8     # the shadow sits lower than the window (design: 12px offset)
SHADOW_ALPHA = 0.30
C = 64            # stretchable edge/centre cells
B = 2             # border width
R_BOTTOM = 4      # bottom corner radius (see module docstring)
TITLE_H = 48
BTN = 32


# ---- shadow ---------------------------------------------------------------
def rounded_rect_sdf(px, py, win, r_top):
    """Signed distance from (px, py) to the window outline (rounded top
    corners r_top, bottom corners R_BOTTOM); negative inside."""
    x0, y0, x1, y1 = win
    r = r_top if py < (y0 + y1) / 2 else R_BOTTOM
    cx, cy = (x0 + x1) / 2, (y0 + y1) / 2
    qx = abs(px - cx) - ((x1 - x0) / 2 - r)
    qy = abs(py - cy) - ((y1 - y0) / 2 - r)
    return math.hypot(max(qx, 0), max(qy, 0)) + min(max(qx, qy), 0) - r


def shadow_alpha(px, py, win, r_top, scale):
    """Shadow opacity at a pixel centre; zero under the window itself."""
    if rounded_rect_sdf(px, py, win, r_top) <= 0:
        return 0.0
    d = rounded_rect_sdf(px, py - SHADOW_DY, win, r_top)
    if d <= 0:
        return SHADOW_ALPHA * scale
    t = min(1.0, d / (PAD + 4))
    return SHADOW_ALPHA * scale * (1 - t) ** 2.2


def png_data_uri(w, h, alpha_at):
    rows = []
    for y in range(h):
        row = bytearray([0])
        for x in range(w):
            a = max(0, min(255, round(alpha_at(x + 0.5, y + 0.5) * 255)))
            row += bytes((0, 0, 0, a))
        rows.append(bytes(row))
    raw = zlib.compress(b"".join(rows), 9)

    def chunk(t, d):
        return struct.pack(">I", len(d)) + t + d + struct.pack(">I", zlib.crc32(t + d) & 0xFFFFFFFF)

    png = (b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 6, 0, 0, 0))
           + chunk(b"IDAT", raw) + chunk(b"IEND", b""))
    return "data:image/png;base64," + base64.b64encode(png).decode()


# ---- window frame -----------------------------------------------------------
def frame(prefix, ox, oy, r, border, shadow_scale):
    """The nine cells of one decoration state, laid out at (ox, oy).

    The cells tile a virtual window whose frame starts PAD in from the outer
    edge: the side columns are PAD + r wide, the top row PAD + r tall, the
    bottom row PAD + R_BOTTOM tall. Every cell's content stays inside its
    own rect -- KSvg sizes frame pieces from their SVG bounds, so nothing may
    spill over (no clip paths, no strokes)."""
    L, Bt, rb = PAD + r, PAD + R_BOTTOM, R_BOTTOM
    W, H = 2 * L + C, L + C + Bt
    win = (PAD, PAD, W - PAD, H - PAD)
    y1 = H - PAD                                   # window bottom edge
    fill = 'class="ColorScheme-Background" fill="currentColor"'
    bcls, bop = border
    line = f'class="{bcls}" fill="currentColor" fill-opacity="{bop}"'

    def X(x, right):                               # mirror for the right column
        return W - x if right else x

    def corner_top(right):
        sw = 0 if right else 1
        a, b = X(PAD, right), X(L, right)
        body = f"M{a},{L} A{r},{r} 0 0 {sw} {b},{PAD} L{b},{L} Z"
        ring = (f"M{a},{L} A{r},{r} 0 0 {sw} {b},{PAD} L{b},{PAD + B} "
                f"A{r - B},{r - B} 0 0 {1 - sw} {X(PAD + B, right)},{L} Z")
        return body, ring

    def corner_bottom(right):
        sw = 0 if right else 1
        top = L + C
        a, c, e = X(PAD, right), X(PAD + rb, right), X(L, right)
        body = (f"M{a},{top} A{rb},{rb} 0 0 {1 - sw} {c},{y1} L{e},{y1} L{e},{top} Z")
        ring = (f"M{a},{top} A{rb},{rb} 0 0 {1 - sw} {c},{y1} L{e},{y1} L{e},{y1 - B} L{c},{y1 - B} "
                f"A{rb - B},{rb - B} 0 0 {sw} {X(PAD + B, right)},{top} Z")
        return body, ring

    def rect(x, y, w, h, attrs):
        if w < 0:
            x, w = x + w, -w
        return f'<rect x="{x}" y="{y}" width="{w}" height="{h}" {attrs}/>'

    cells = {}
    for right in (False, True):
        side = "right" if right else "left"
        cx = W - L if right else 0
        body, ring = corner_top(right)
        cells["top" + side] = ((cx, 0, L, L), f'<path d="{body}" {fill}/><path d="{ring}" {line}/>')
        body, ring = corner_bottom(right)
        cells["bottom" + side] = ((cx, L + C, L, Bt), f'<path d="{body}" {fill}/><path d="{ring}" {line}/>')
        bx = W - L if right else PAD                       # body strip of the side edge
        lx = W - PAD - B if right else PAD                 # its border line
        cells[side] = ((cx, L, L, C), rect(bx, L, r, C, fill) + rect(lx, L, B, C, line))
    cells["top"] = ((L, 0, C, L), rect(L, PAD, C, r, fill) + rect(L, PAD, C, B, line))
    cells["bottom"] = ((L, L + C, C, Bt), rect(L, L + C, C, rb, fill) + rect(L, y1 - B, C, B, line))
    cells["center"] = ((L, L, C, C), rect(L, L, C, C, fill))

    out = []
    for name, ((cx, cy, cw, ch), shape) in cells.items():
        parts = [f'<rect x="{cx}" y="{cy}" width="{cw}" height="{ch}" fill="none"/>']
        if name != "center":
            uri = png_data_uri(cw, ch, lambda x, y, cx=cx, cy=cy:
                               shadow_alpha(cx + x, cy + y, win, r, shadow_scale))
            parts.append(f'<image x="{cx}" y="{cy}" width="{cw}" height="{ch}" xlink:href="{uri}"/>')
        parts.append(shape)
        out.append(f'<g id="{prefix}-{name}" transform="translate({ox},{oy})">{"".join(parts)}</g>')
    return [], out, (W, H)


def decoration_svg(r, dark_text):
    defs, body = [], []
    states = [("decoration", ("ColorScheme-Highlight", 0.65), 1.0),
              ("decoration-inactive", ("ColorScheme-Text", 0.16), 0.6)]
    x = 0
    for prefix, border, scale in states:
        d, o, (w, h) = frame(prefix, x, 0, r, border, scale)
        defs += d
        body += o
        x += w + 20
    # maximised: square, no border, no shadow -- only the centre is used
    for i, prefix in enumerate(("decoration-maximized", "decoration-maximized-inactive")):
        body.append(f'<rect id="{prefix}-center" x="{x + i * (C + 20)}" y="0" width="{C}" height="{C}" '
                    f'class="ColorScheme-Background" fill="currentColor"/>')
    width = x + 2 * (C + 20)
    height = h
    return f"""<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="{width}" height="{height}" viewBox="0 0 {width} {height}">
<!-- Generated by scripts/generate-aurorae-theme.py; do not edit by hand. -->
<defs>
<style type="text/css" id="current-color-scheme">
.ColorScheme-Background {{ color:{"#12101b" if dark_text else "#fdf8ff"}; }}
.ColorScheme-Highlight {{ color:#cdacff; }}
.ColorScheme-Text {{ color:{"#e5e3ec" if dark_text else "#1c1b20"}; }}
</style>
{"".join(defs)}
</defs>
{chr(10).join(body)}
<!-- stretch the edge cells instead of tiling them: tiled soft shadows show a
     seam at every tile boundary (same as the Plasma theme's panels) -->
<rect id="hint-stretch-borders" x="0" y="0" width="1" height="1" fill="none"/>
</svg>
"""


# ---- buttons ------------------------------------------------------------------
GLYPHS = {
    # Material Symbols Rounded look: 2 px strokes with round ends, drawn as
    # filled outlines of a 32 px cell (the design's 18 px glyphs).
    "minimize": [("line", 10.5, 16, 21.5, 16)],
    # open_in_full: arrows out to the top-right and bottom-left corners
    "maximize": [("line", 13, 19, 19, 13), ("poly", [(15, 10.5), (21.5, 10.5), (21.5, 17)]),
                 ("poly", [(10.5, 15), (10.5, 21.5), (17, 21.5)])],
    # close_fullscreen: arrows in towards the centre
    "restore": [("line", 11, 21, 15, 17), ("line", 17, 15, 21, 11),
                ("poly", [(11.5, 17), (15, 17), (15, 20.5)]), ("poly", [(17, 11.5), (17, 15), (20.5, 15)])],
    "close": [("line", 11, 11, 21, 21), ("line", 21, 11, 11, 21)],
}


def glyph(kind, ox, oy, opacity):
    sw = 2
    parts = []
    for g in GLYPHS[kind]:
        if g[0] == "line":
            _, a, b, c, d = g
            parts.append(f"M{ox + a},{oy + b} L{ox + c},{oy + d}")
        else:
            pts = g[1]
            parts.append("M" + " L".join(f"{ox + x},{oy + y}" for x, y in pts))
    d = " ".join(parts)
    return (f'<path d="{d}" fill="none" class="ColorScheme-Text" stroke="currentColor" '
            f'stroke-width="{sw}" stroke-linecap="round" stroke-linejoin="round" opacity="{opacity}"/>')


def button_svg(kind, hover_r):
    close = kind == "close"
    hover_cls, hover_op, press_op = (("ColorScheme-NegativeText", 0.35, 0.5) if close
                                     else ("ColorScheme-Highlight", 0.22, 0.34))
    rest = ("ColorScheme-ButtonBackground", 1.0)
    # (prefix, fill class, fill opacity, shaped, glyph opacity)
    states = [
        ("active", *rest, False, 1.0),
        ("hover", hover_cls, hover_op, True, 1.0),
        ("pressed", hover_cls, press_op, True, 1.0),
        ("inactive", rest[0], 0.6, False, 0.62),
        ("hover-inactive", hover_cls, hover_op, True, 1.0),
        ("pressed-inactive", hover_cls, press_op, True, 1.0),
        ("deactivated", rest[0], 0.6, False, 0.3),
        ("deactivated-inactive", rest[0], 0.4, False, 0.25),
    ]
    out = []
    for i, (prefix, cls, op, shaped, gop) in enumerate(states):
        x = i * (BTN + 8)
        rx = hover_r if (shaped and hover_r is not None) else BTN / 2
        out.append(
            f'<g id="{prefix}-center"><rect x="{x}" y="0" width="{BTN}" height="{BTN}" fill="none"/>'
            f'<rect x="{x}" y="0" width="{BTN}" height="{BTN}" rx="{rx}" class="{cls}" fill="currentColor" '
            f'fill-opacity="{op}"/>{glyph(kind, x, 0, gop)}</g>')
    width = len(states) * (BTN + 8)
    return f"""<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{BTN}" viewBox="0 0 {width} {BTN}">
<!-- Generated by scripts/generate-aurorae-theme.py; do not edit by hand. -->
<defs><style type="text/css" id="current-color-scheme">
.ColorScheme-ButtonBackground {{ color:#262331; }}
.ColorScheme-Highlight {{ color:#cdacff; }}
.ColorScheme-NegativeText {{ color:#ff9b93; }}
.ColorScheme-Text {{ color:#e5e3ec; }}
</style></defs>
{chr(10).join(out)}
</svg>
"""


# ---- rc + metadata -------------------------------------------------------------
def rgba(hex_color, a=1.0):
    h = hex_color.lstrip("#")
    return ",".join(str(int(h[i:i + 2], 16)) for i in (0, 2, 4)) + f",{round(a * 255)}"


def rc(text_hex, r, dur):
    edge_top = (TITLE_H - BTN) // 2
    return f"""# Generated by scripts/generate-aurorae-theme.py; do not edit by hand.
[General]
TitleAlignment=Left
TitleVerticalAlignment=Center
Animation={dur}
ActiveTextColor={rgba(text_hex)}
InactiveTextColor={rgba(text_hex, 0.62)}
UseTextShadow=false
LeftButtons=M
RightButtons=IAX
Shadow=true

[Layout]
BorderLeft={B}
BorderRight={B}
BorderBottom={B}
TitleEdgeTop={edge_top}
TitleEdgeBottom={edge_top}
TitleEdgeLeft=14
TitleEdgeRight=8
TitleEdgeTopMaximized={edge_top}
TitleEdgeBottomMaximized={edge_top}
TitleEdgeLeftMaximized=14
TitleEdgeRightMaximized=8
TitleBorderLeft=10
TitleBorderRight=10
TitleHeight={BTN}
ButtonWidth={BTN}
ButtonWidthMenu=20
ButtonHeight={BTN}
ButtonSpacing=4
ButtonMarginTop=0
ExplicitButtonSpacer=8
PaddingTop={PAD}
PaddingBottom={PAD}
PaddingLeft={PAD}
PaddingRight={PAD}
"""


def metadata(name, variant, dark):
    label = "AedwenOS" + (" (stock M3)" if variant == "baseline" else "") + (" Dark" if dark else " Light")
    return f"""[Desktop Entry]
Name={label}
Comment=AedwenOS window title bars, Material 3 {"Expressive" if variant == "expressive" else ""}, following the colour scheme
X-KDE-PluginInfo-Name={name}
X-KDE-PluginInfo-Author=AedwenOS
X-KDE-PluginInfo-Version=1.0
X-KDE-PluginInfo-License=GPL-3.0-or-later
"""


def theme_name(variant, dark):
    return "AedwenOS" + ("-Baseline" if variant == "baseline" else "") + ("-Dark" if dark else "-Light")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default=OUT)
    ap.add_argument("--seed", default=DEFAULT_SEED, choices=SEEDS.keys(),
                    help="only for the title text colour (on-surface); fills follow the scheme")
    args = ap.parse_args()

    for variant in VARIANTS:
        sh = shapes(variant)
        for dark in (True, False):
            name = theme_name(variant, dark)
            text = palette(SEEDS[args.seed], dark, variant == "expressive")["on-s"]
            d = os.path.join(args.out, name)
            os.makedirs(d, exist_ok=True)
            with open(os.path.join(d, "decoration.svg"), "w") as f:
                f.write(decoration_svg(sh["r_win"], dark))
            for kind in GLYPHS:
                with open(os.path.join(d, f"{kind}.svg"), "w") as f:
                    f.write(button_svg(kind, sh["ctl_hover_r"]))
            with open(os.path.join(d, f"{name}rc"), "w") as f:
                f.write(rc(text, sh["r_win"], 180))
            with open(os.path.join(d, "metadata.desktop"), "w") as f:
                f.write(metadata(name, variant, dark))
            print(f"Wrote {d}")


if __name__ == "__main__":
    main()
