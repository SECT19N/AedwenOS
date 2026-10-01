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

  widgets/panel-background   top bar and dock: surface-container, r 20
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
    scripts/generate-plasma-theme.py [--out DIR] [--acrylic 0.86]
"""

import argparse
import gzip
import json
import os

THEME = "iso/airootfs/usr/share/plasma/desktoptheme/aedwen"

# name -> (colour class, corner radius, content margin, shadow size, shadow alpha)
FRAMES = {
    "widgets/panel-background": ("HeaderBackground", 20, 6, 12, 0.22),
    "dialogs/background": ("ButtonBackground", 32, 12, 28, 0.32),
    "widgets/tooltip": ("TooltipBackground", 8, 8, 10, 0.24),
    "widgets/background": ("HeaderBackground", 20, 12, 14, 0.18),
}
CENTER = 8          # size of the stretchable centre/edge cells


def frame_elements(prefix, ox, oy, r, cls, opacity, hairline):
    """The 9 cells of a rounded frame with corner radius r, laid out at
    (ox, oy). `prefix` is "" or "mask-"."""
    c = CENTER
    fill = f'class="ColorScheme-{cls}" fill="currentColor" fill-opacity="{opacity}"'
    line = 'class="ColorScheme-Text" fill="none" stroke="currentColor" stroke-opacity="0.08" stroke-width="1"'
    out = []

    def g(name, body):
        out.append(f'<g id="{prefix}{name}">{body}</g>')

    # corners: the quarter disc of radius r inside an r x r cell
    corners = {
        "topleft": (ox, oy, f"M{ox},{oy + r} A{r},{r} 0 0 1 {ox + r},{oy} L{ox + r},{oy + r} Z",
                    f"M{ox + 0.5},{oy + r} A{r - 0.5},{r - 0.5} 0 0 1 {ox + r},{oy + 0.5}"),
        "topright": (ox + r + c, oy, f"M{ox + r + c},{oy} A{r},{r} 0 0 1 {ox + 2 * r + c},{oy + r} L{ox + r + c},{oy + r} Z",
                     f"M{ox + r + c},{oy + 0.5} A{r - 0.5},{r - 0.5} 0 0 1 {ox + 2 * r + c - 0.5},{oy + r}"),
        "bottomright": (ox + r + c, oy + r + c, f"M{ox + 2 * r + c},{oy + r + c} A{r},{r} 0 0 1 {ox + r + c},{oy + 2 * r + c} L{ox + r + c},{oy + r + c} Z",
                        f"M{ox + 2 * r + c - 0.5},{oy + r + c} A{r - 0.5},{r - 0.5} 0 0 1 {ox + r + c},{oy + 2 * r + c - 0.5}"),
        "bottomleft": (ox, oy + r + c, f"M{ox + r},{oy + 2 * r + c} A{r},{r} 0 0 1 {ox},{oy + r + c} L{ox + r},{oy + r + c} Z",
                       f"M{ox + r},{oy + 2 * r + c - 0.5} A{r - 0.5},{r - 0.5} 0 0 1 {ox + 0.5},{oy + r + c}"),
    }
    for name, (x, y, d, arc) in corners.items():
        # an invisible rect pins the element's bounds to the full cell
        body = f'<rect x="{x}" y="{y}" width="{r}" height="{r}" fill="none"/><path d="{d}" {fill}/>'
        if hairline:
            body += f'<path d="{arc}" {line}/>'
        g(name, body)

    edges = {
        "top": (ox + r, oy, c, r, (ox + r, oy + 0.5, ox + r + c, oy + 0.5)),
        "bottom": (ox + r, oy + r + c, c, r, (ox + r, oy + 2 * r + c - 0.5, ox + r + c, oy + 2 * r + c - 0.5)),
        "left": (ox, oy + r, r, c, (ox + 0.5, oy + r, ox + 0.5, oy + r + c)),
        "right": (ox + r + c, oy + r, r, c, (ox + 2 * r + c - 0.5, oy + r, ox + 2 * r + c - 0.5, oy + r + c)),
    }
    for name, (x, y, w, h, (x1, y1, x2, y2)) in edges.items():
        body = f'<rect x="{x}" y="{y}" width="{w}" height="{h}" {fill}/>'
        if hairline:
            body += f'<path d="M{x1},{y1} L{x2},{y2}" {line}/>'
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


def frame_svg(cls, r, margin, s, a, opacity):
    c = CENTER
    size = 2 * r + c
    tsize = 2 * (s + r) + c
    mx = size + 20                        # mask frame to the right
    sy = size + 20                        # shadow frame below
    parts = []
    parts += frame_elements("", 0, 0, r, cls, opacity, hairline=opacity < 1)
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
    ap.add_argument("--out", default=THEME)
    ap.add_argument("--acrylic", type=float, default=0.86,
                    help="background opacity of the blurred (non-solid) variants")
    args = ap.parse_args()

    for name, (cls, r, margin, s, a) in FRAMES.items():
        for variant, opacity in (("", args.acrylic), ("translucent/", args.acrylic),
                                 ("solid/", 1.0), ("opaque/", 1.0)):
            write_svgz(os.path.join(args.out, variant + name + ".svgz"),
                       frame_svg(cls, r, margin, s, a, opacity))
    with open(os.path.join(args.out, "metadata.json"), "w") as f:
        json.dump(METADATA, f, indent=4)
        f.write("\n")
    with open(os.path.join(args.out, "plasmarc"), "w") as f:
        f.write(PLASMARC)
    print(f"Wrote {len(FRAMES)} frames x 4 variants to {args.out}")


if __name__ == "__main__":
    main()
