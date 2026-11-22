#!/usr/bin/env python3
"""
Generate the "aedwen" Plasma desktop theme
(iso/airootfs/usr/share/plasma/desktoptheme/aedwen/): the frames Plasma
draws behind panels, popups, tooltips and desktop widgets, shaped per the
AedwenOS System Surfaces design (Material 3 Expressive corners) with the
light acrylic blur the Desktop design asks for.

No colours are baked in. Every fill uses a KDE colour class
(ColorScheme-HeaderBackground, -ButtonBackground, -TooltipBackground, ...),
which Plasma substitutes from the active colour scheme, and the theme ships
no `colors` file -- so the shell follows whatever scheme is selected, like
org.aedwen.ui's Theme does.

  widgets/panel-background   top bar and dock: surface-container, r 16
                             (the design's baseline r-bar; clean down to 32 px thick)
  dialogs/background         popups (launcher, quick settings, ...):
                             surface-container-high, r 32 (r-pop)
  widgets/tooltip            inverse surface, r 8
  widgets/background         desktop widgets: surface-container, r 20 (r-card)

Each is written four times: the base and translucent/ variants are
see-through (blurred by KWin through plasmarc's BlurBehindEffect); solid/
(Plasma's opaque-panel mode) and opaque/ (no compositing) are fully opaque.
Every frame has mask-* elements (so the blur follows the rounded corners)
and shadow-* elements.

Usage:
    scripts/generate-plasma-theme.py [--out DIR] [--acrylic 0.86] [--contrast high]
"""

import argparse
import gzip
import json
import os

THEME = "iso/airootfs/usr/share/plasma/desktoptheme/aedwen"

# name -> (colour class, corner radius, content margin, shadow size, shadow alpha)
FRAMES = {
    "widgets/panel-background": ("HeaderBackground", 16, 6, 12, 0.22),
    "dialogs/background": ("ButtonBackground", 32, 12, 28, 0.32),
    "widgets/tooltip": ("TooltipBackground", 8, 8, 10, 0.24),
    "widgets/background": ("HeaderBackground", 20, 12, 14, 0.18),
}
# Size of the stretchable centre/edge cells. Plasma stretches them (see
# hint-stretch-borders below) rather than tiling: tiling small cells of a
# see-through fill leaves a seam at every tile boundary that falls between
# device pixels (fractional scaling, VMs), drawn as a dotted or striped
# pattern along the panel.
CENTER = 64


def frame_elements(prefix, ox, oy, r, cls, opacity, hairline, lw=1, la=0.08):
    """The 9 cells of a rounded frame with corner radius r, laid out at
    (ox, oy). `prefix` is "" or "mask-"."""
    c = CENTER
    fill = f'class="ColorScheme-{cls}" fill="currentColor" fill-opacity="{opacity}"'
    # The hairline is a filled 1px shape, not a stroke: a stroke's bounds
    # spill half a pixel outside the cell, so Plasma would shrink the cell's
    # fill to make room and leave a see-through gap at every join.
    # (high contrast: lw = 2 px at full strength, la = 1)
    line = f'class="ColorScheme-Text" fill="currentColor" fill-opacity="{la}"'
    out = []

    def g(name, body):
        out.append(f'<g id="{prefix}{name}">{body}</g>')

    # corners: the quarter disc of radius r inside an r x r cell
    def quarter(cx, cy, sx, sy, rad):
        """Quarter disc of radius rad centred on (cx, cy), opening towards
        (-sx, -sy): the rounded part of a corner cell."""
        sweep = 1 if sx == sy else 0
        return (f"M{cx - sx * rad},{cy} A{rad},{rad} 0 0 {sweep} {cx},{cy - sy * rad} "
                f"L{cx},{cy} Z")

    def ring(cx, cy, sx, sy):
        sweep = 1 if sx == sy else 0
        return (f"M{cx - sx * r},{cy} A{r},{r} 0 0 {sweep} {cx},{cy - sy * r} "
                f"L{cx},{cy - sy * (r - lw)} A{r - lw},{r - lw} 0 0 {1 - sweep} {cx - sx * (r - lw)},{cy} Z")

    # (cell origin, centre of the rounding, direction of the outer corner)
    cells = {
        "topleft": (ox, oy, ox + r, oy + r, 1, 1),
        "topright": (ox + r + c, oy, ox + r + c, oy + r, -1, 1),
        "bottomright": (ox + r + c, oy + r + c, ox + r + c, oy + r + c, -1, -1),
        "bottomleft": (ox, oy + r + c, ox + r, oy + r + c, 1, -1),
    }
    corners = {name: (x, y, quarter(cx, cy, sx, sy, r), ring(cx, cy, sx, sy))
                for name, (x, y, cx, cy, sx, sy) in cells.items()}
    for name, (x, y, d, arc) in corners.items():
        # an invisible rect pins the element's bounds to the full cell
        body = f'<rect x="{x}" y="{y}" width="{r}" height="{r}" fill="none"/><path d="{d}" {fill}/>'
        if hairline:
            body += f'<path d="{arc}" {line}/>'
        g(name, body)

    edges = {
        "top": (ox + r, oy, c, r, (ox + r, oy, c, lw)),
        "bottom": (ox + r, oy + r + c, c, r, (ox + r, oy + 2 * r + c - lw, c, lw)),
        "left": (ox, oy + r, r, c, (ox, oy + r, lw, c)),
        "right": (ox + r + c, oy + r, r, c, (ox + 2 * r + c - lw, oy + r, lw, c)),
    }
    for name, (x, y, w, h, (lx, ly, lw, lh)) in edges.items():
        body = f'<rect x="{x}" y="{y}" width="{w}" height="{h}" {fill}/>'
        if hairline:
            body += f'<rect x="{lx}" y="{ly}" width="{lw}" height="{lh}" {line}/>'
        g(name, body)
    g("center", f'<rect x="{ox + r}" y="{oy + r}" width="{c}" height="{c}" {fill}/>')
    return out


def shadow_elements(ox, oy, r, s, a):
    """shadow-* cells: a soft falloff of width s outside a rounded rect of
    radius r. Cells are (s + r) thick; the part under the frame itself stays
    empty so the shadow doesn't darken a see-through background."""
    c, t = CENTER, s + r
    out, defs = [], []
    stops = lambda gid, extra: (
        f'<{gid} {extra}><stop offset="0" stop-color="#000" stop-opacity="{a}"/>'
        f'<stop offset="0.35" stop-color="#000" stop-opacity="{a * 0.45:.3f}"/>'
        f'<stop offset="0.7" stop-color="#000" stop-opacity="{a * 0.12:.3f}"/>'
        f'<stop offset="1" stop-color="#000" stop-opacity="0"/></{gid.split()[0]}>')

    def corner(name, cx, cy, x, y):
        gid = f"sh-{name}"
        k = r / t
        defs.append(
            f'<radialGradient id="{gid}" gradientUnits="userSpaceOnUse" cx="{cx}" cy="{cy}" r="{t}">'
            f'<stop offset="{k:.4f}" stop-color="#000" stop-opacity="{a}"/>'
            f'<stop offset="{k + (1 - k) * 0.35:.4f}" stop-color="#000" stop-opacity="{a * 0.45:.3f}"/>'
            f'<stop offset="{k + (1 - k) * 0.7:.4f}" stop-color="#000" stop-opacity="{a * 0.12:.3f}"/>'
            f'<stop offset="1" stop-color="#000" stop-opacity="0"/></radialGradient>')
        # the cell minus the frame's rounded corner (evenodd)
        sx = 1 if cx > x else -1
        sy = 1 if cy > y else -1
        d = (f"M{x},{y} h{t * sx * 1} v{t * sy} h{-t * sx} Z "
             f"M{cx},{cy - r * sy} A{r},{r} 0 0 {1 if sx * sy < 0 else 0} {cx - r * sx},{cy} L{cx},{cy} Z")
        out.append(f'<g id="shadow-{name}"><rect x="{min(x, x + t * sx)}" y="{min(y, y + t * sy)}" width="{t}" height="{t}" fill="none"/>'
                   f'<path d="{d}" fill="url(#{gid})" fill-rule="evenodd"/></g>')

    corner("topleft", ox + t, oy + t, ox, oy)
    corner("topright", ox + t + c, oy + t, ox + 2 * t + c, oy)
    corner("bottomright", ox + t + c, oy + t + c, ox + 2 * t + c, oy + 2 * t + c)
    corner("bottomleft", ox + t, oy + t + c, ox, oy + 2 * t + c)

    def edge(name, x, y, w, h, x1, y1, x2, y2, bx, by, bw, bh):
        gid = f"sh-{name}"
        defs.append(stops(f'linearGradient id="{gid}"', f'gradientUnits="userSpaceOnUse" x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}"'))
        out.append(f'<g id="shadow-{name}"><rect x="{x}" y="{y}" width="{w}" height="{h}" fill="none"/>'
                   f'<rect x="{bx}" y="{by}" width="{bw}" height="{bh}" fill="url(#{gid})"/></g>')

    # (cell rect, gradient from the frame edge outwards, falloff band)
    edge("top", ox + t, oy, c, t, 0, oy + s, 0, oy, ox + t, oy, c, s)
    edge("bottom", ox + t, oy + t + c, c, t, 0, oy + t + c + r, 0, oy + t + c + r + s,
         ox + t, oy + t + c + r, c, s)
    edge("left", ox, oy + t, t, c, ox + s, 0, ox, 0, ox, oy + t, s, c)
    edge("right", ox + t + c, oy + t, t, c, ox + t + c + r, 0, ox + t + c + r + s, 0,
         ox + t + c + r, oy + t, s, c)
    out.append(f'<g id="shadow-center"><rect x="{ox + t}" y="{oy + t}" width="{c}" height="{c}" fill="none"/></g>')
    return defs, out


def hint(name, x, y, w, h):
    return f'<rect id="{name}" x="{x}" y="{y}" width="{w}" height="{h}" fill="#ff00ff" fill-opacity="0"/>'


def frame_svg(cls, r, margin, s, a, opacity, hc=False):
    c = CENTER
    size = 2 * r + c
    tsize = 2 * (s + r) + c
    mx = size + 20                        # mask frame to the right
    sy = size + 20                        # shadow frame below
    parts = []
    parts += frame_elements("", 0, 0, r, cls, opacity, hairline=opacity < 1 or hc,
                            lw=2 if hc else 1, la=1 if hc else 0.08)
    parts += frame_elements("mask-", mx, 0, r, cls, 1, hairline=False)
    defs, shadow = shadow_elements(0, sy, r, s, a)
    parts += shadow
    # content margins (how far the contents sit from the frame edge) and
    # shadow extents; insets are 0 (contents may reach the frame edge)
    for side in ("top", "bottom", "left", "right"):
        horiz = side in ("left", "right")
        w, h = (margin, 1) if horiz else (1, margin)
        parts.append(hint(f"hint-{side}-margin", 0, 0, w, h))
        w, h = (s, 1) if horiz else (1, s)
        parts.append(hint(f"shadow-hint-{side}-margin", 0, sy, w, h))
        w, h = (0.0001, 1) if horiz else (1, 0.0001)
        parts.append(hint(f"hint-{side}-inset", 0, 0, w, h))
    parts.append(hint("hint-stretch-borders", 0, 0, 1, 1))
    width = max(mx + size, tsize) + 10
    height = sy + tsize + 10
    body = "\n".join(parts)
    return f"""<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" viewBox="0 0 {width} {height}">
<!-- Generated by scripts/generate-plasma-theme.py; do not edit by hand. -->
<defs>
<style type="text/css" id="current-color-scheme">
.ColorScheme-Text {{ color:#e5e3ec; }}
.ColorScheme-{cls} {{ color:#1f1c29; }}
</style>
{''.join(defs)}
</defs>
{body}
</svg>
"""


PLASMARC = """[ContrastEffect]
enabled=true
contrast=0.3
intensity=1.6
saturation=1.7

[BlurBehindEffect]
enabled=true

[AdaptiveTransparency]
enabled=true
"""

PLASMARC_HC = """[ContrastEffect]
enabled=false

[BlurBehindEffect]
enabled=false

[AdaptiveTransparency]
enabled=false
"""

METADATA = {
    "KPlugin": {
        "Authors": [{"Name": "AedwenOS"}],
        "Category": "",
        "Description": "Material 3 Expressive shell surfaces for AedwenOS, following the active colour scheme",
        "EnabledByDefault": True,
        "Id": "aedwen",
        "License": "GPL-3.0-or-later",
        "Name": "AedwenOS",
        "Version": "1.0",
    },
    "X-Plasma-API": "5.0",
}


def write_svgz(path, text):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with gzip.open(path, "wt") as f:
        f.write(text)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--contrast", choices=("standard", "high"), default="standard",
                    help="high: the aedwen-hc theme (opaque, no blur, 2px full-strength outline)")
    ap.add_argument("--out", default=None)
    ap.add_argument("--acrylic", type=float, default=0.86,
                    help="background opacity of the blurred (non-solid) variants")
    args = ap.parse_args()
    hc = args.contrast == "high"
    out = args.out or (THEME + "-hc" if hc else THEME)
    acrylic = 1.0 if hc else args.acrylic

    for name, (cls, r, margin, s, a) in FRAMES.items():
        for variant, opacity in (("", acrylic), ("translucent/", acrylic),
                                 ("solid/", 1.0), ("opaque/", 1.0)):
            write_svgz(os.path.join(out, variant + name + ".svgz"),
                       frame_svg(cls, r, margin, s, a, opacity, hc))
    meta = json.loads(json.dumps(METADATA))
    if hc:
        meta["KPlugin"].update({"Id": "aedwen-hc", "Name": "AedwenOS High Contrast",
                                "Description": "AedwenOS shell surfaces: opaque, no blur, 2 px outline"})
    with open(os.path.join(out, "metadata.json"), "w") as f:
        json.dump(meta, f, indent=4)
        f.write("\n")
    with open(os.path.join(out, "plasmarc"), "w") as f:
        f.write(PLASMARC_HC if hc else PLASMARC)
    args.out = out
    print(f"Wrote {len(FRAMES)} frames x 4 variants to {args.out}")


if __name__ == "__main__":
    main()
