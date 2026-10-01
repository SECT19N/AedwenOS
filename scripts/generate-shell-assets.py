#!/usr/bin/env python3
"""
Generate the binary assets of the org.aedwen.ui QML module
(iso/airootfs/usr/lib/qt6/qml/org/aedwen/ui/), the component library the
AedwenOS Plasma widgets are built on:

  - fonts/MaterialSymbolsRounded.ttf + LICENSE
                 Material Symbols Rounded (Apache-2.0) with every icon, so
                 widgets can show any symbol by name (the font's ligatures
                 turn "search" into the search glyph). Instanced to GRAD 0 /
                 opsz 24 and wght 400-600 to keep it ~3 MB; the FILL axis is
                 kept for outlined vs filled icons.
  - images/eagle.svg
                 The AedwenOS eagle traced from logo.png into a vector path,
                 written as a KDE "symbolic" SVG (fill = currentColor with
                 the ColorScheme-Text class) so EagleMark / Kirigami.Icon can
                 recolour it at runtime -- with any Qt Quick backend, unlike
                 a shader effect on a PNG.

Colours are not baked into anything here: org.aedwen.ui's Theme reads them
from the active KDE colour scheme at runtime.

The full font is downloaded from github.com/google/material-design-icons
unless --symbols-font points at a local copy.

Usage:
    scripts/generate-shell-assets.py [--symbols-font MaterialSymbolsRounded[...].ttf]

Requires fonttools and python-cairo.
"""

import argparse
import os
import subprocess
import sys
import tempfile
import urllib.request

import cairo

MODULE = "iso/airootfs/usr/lib/qt6/qml/org/aedwen/ui"
LOGO = "iso/airootfs/etc/calamares/branding/aedwenos/logo.png"
FONT_URL = ("https://github.com/google/material-design-icons/raw/master/variablefont/"
            "MaterialSymbolsRounded%5BFILL,GRAD,opsz,wght%5D.ttf")
LICENSE_URL = "https://raw.githubusercontent.com/google/material-design-icons/master/LICENSE"


def fetch(url, dest):
    print(f"downloading {url}")
    urllib.request.urlretrieve(url, dest)
    return dest


def alpha_grid(src, size):
    """logo.png's alpha, cropped to the bird, centred in a size x size grid
    (list of rows of 0..1)."""
    logo = cairo.ImageSurface.create_from_png(src)
    w, h, stride = logo.get_width(), logo.get_height(), logo.get_stride()
    data = logo.get_data()
    rows = [y for y in range(h) if any(data[y * stride + x * 4 + 3] for x in range(0, w, 2))]
    cols = [x for x in range(w) if any(data[y * stride + x * 4 + 3] for y in range(rows[0], rows[-1] + 1, 2))]
    x0, y0, bw, bh = cols[0], rows[0], cols[-1] - cols[0] + 1, rows[-1] - rows[0] + 1
    inner = size - 4                       # keep a 2px border so contours close
    scale = inner / max(bw, bh)
    surface = cairo.ImageSurface(cairo.FORMAT_A8, size, size)
    ctx = cairo.Context(surface)
    ctx.translate((size - bw * scale) / 2, (size - bh * scale) / 2)
    ctx.scale(scale, scale)
    ctx.mask_surface(logo, -x0, -y0)
    surface.flush()
    st, buf = surface.get_stride(), surface.get_data()
    return [[buf[y * st + x] / 255 for x in range(size)] for y in range(size)]


def contours(grid, level=0.5):
    """Marching squares: closed iso-lines of `grid` at `level`, as lists of
    (x, y) points, with linear interpolation along cell edges."""
    n = len(grid)

    def interp(a, b, pa, pb):
        t = (level - a) / (b - a) if b != a else 0.5
        return (pa[0] + (pb[0] - pa[0]) * t, pa[1] + (pb[1] - pa[1]) * t)

    # Each cell contributes segments between edge midpoints; edges are keyed
    # so segments can be chained into loops afterwards.
    segs = {}
    for y in range(n - 1):
        for x in range(n - 1):
            tl, tr, br, bl = grid[y][x], grid[y][x + 1], grid[y + 1][x + 1], grid[y + 1][x]
            idx = (tl > level) * 8 | (tr > level) * 4 | (br > level) * 2 | (bl > level)
            if idx in (0, 15):
                continue
            e = {
                "t": (("h", x, y), lambda: interp(tl, tr, (x, y), (x + 1, y))),
                "r": (("v", x + 1, y), lambda: interp(tr, br, (x + 1, y), (x + 1, y + 1))),
                "b": (("h", x, y + 1), lambda: interp(bl, br, (x, y + 1), (x + 1, y + 1))),
                "l": (("v", x, y), lambda: interp(tl, bl, (x, y), (x, y + 1))),
            }
            table = {1: ["lb"], 2: ["br"], 3: ["lr"], 4: ["rt"], 5: ["lt", "rb"], 6: ["bt"],
                     7: ["lt"], 8: ["tl"], 9: ["tb"], 10: ["tr", "bl"], 11: ["tr"],
                     12: ["rl"], 13: ["rb"], 14: ["bl"]}[idx]
            for a, b in table:
                ka, pa = e[a][0], e[a][1]()
                kb, pb = e[b][0], e[b][1]()
                segs.setdefault(ka, []).append((kb, pa, pb))
                segs.setdefault(kb, []).append((ka, pb, pa))
    loops, used = [], set()
    for start in list(segs):
        if start in used:
            continue
        loop, prev, cur = [], None, start
        while cur not in used:
            used.add(cur)
            nxt = [s for s in segs[cur] if s[0] != prev and s[0] not in used] or \
                  [s for s in segs[cur] if s[0] != prev]
            if not nxt:
                break
            k, pa, pb = nxt[0]
            loop.append(pa)
            prev, cur = cur, k
        if len(loop) > 8:
            loops.append(loop)
    return loops


def simplify(pts, eps):
    """Ramer-Douglas-Peucker on a closed loop."""
    def rdp(p):
        if len(p) < 3:
            return p
        (x1, y1), (x2, y2) = p[0], p[-1]
        dx, dy = x2 - x1, y2 - y1
        norm = (dx * dx + dy * dy) ** 0.5 or 1e-9
        i, dmax = 0, -1
        for j in range(1, len(p) - 1):
            d = abs(dy * p[j][0] - dx * p[j][1] + x2 * y1 - y2 * x1) / norm
            if d > dmax:
                i, dmax = j, d
        if dmax <= eps:
            return [p[0], p[-1]]
        return rdp(p[: i + 1])[:-1] + rdp(p[i:])
    half = len(pts) // 2
    return rdp(pts[: half + 1])[:-1] + rdp(pts[half:] + [pts[0]])[:-1]


def eagle_svg(src, dest, size=512):
    grid = alpha_grid(src, size)
    paths = []
    for loop in contours(grid):
        pts = simplify(loop, 0.7)
        if len(pts) >= 3:
            paths.append("M" + " L".join(f"{x:.1f} {y:.1f}" for x, y in pts) + "Z")
    with open(dest, "w") as f:
        f.write(f"""<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {size} {size}">
<!-- AedwenOS eagle, traced from logo.png by scripts/generate-shell-assets.py -->
<style type="text/css" id="current-color-scheme">.ColorScheme-Text {{ color:#ffffff; }}</style>
<path class="ColorScheme-Text" fill="currentColor" fill-rule="evenodd" d="{' '.join(paths)}"/>
</svg>
""")
    return len(paths)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default=MODULE)
    ap.add_argument("--symbols-font", help="local MaterialSymbolsRounded[FILL,GRAD,opsz,wght].ttf")
    args = ap.parse_args()

    fonts_dir = os.path.join(args.out, "fonts")
    images_dir = os.path.join(args.out, "images")
    os.makedirs(fonts_dir, exist_ok=True)
    os.makedirs(images_dir, exist_ok=True)

    with tempfile.TemporaryDirectory() as tmp:
        font = args.symbols_font or fetch(FONT_URL, os.path.join(tmp, "msr.ttf"))
        subprocess.run(
            [sys.executable, "-m", "fontTools.varLib.instancer", font,
             "GRAD=0", "opsz=24", "wght=400:600",
             "-o", os.path.join(fonts_dir, "MaterialSymbolsRounded.ttf")],
            check=True,
        )
        fetch(LICENSE_URL, os.path.join(fonts_dir, "LICENSE"))

    n = eagle_svg(LOGO, os.path.join(images_dir, "eagle.svg"))
    print(f"Wrote icon font and eagle ({n} contours) to {args.out}")


if __name__ == "__main__":
    main()
