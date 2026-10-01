#!/usr/bin/env python3
"""
Generate the "Aedwen" Xcursor theme from the cursor geometry in the AedwenOS
System Surfaces design (section 04, "Cursors · Aedwen").

Ported from the design's CURSORS / FAMS / CUR_COLORS tables and its
cursorSvg() renderer: every cursor is drawn on a 32-unit grid as an outline
pass (paper colour, widened stroke, optional soft shadow) under an ink pass.
The design's defaults are family "expressive", style "dark", size 32.
Busy/working cursors are animated: the SVG's rotate + corner-radius
animation is sampled into frames at 12 fps.

Output: iso/airootfs/usr/share/icons/Aedwen/{index.theme,cursors/}, one
Xcursor file per cursor (24/32/48/64 px) plus symlinks for every X11, CSS
and legacy hash name apps look up.

Usage:
    scripts/generate-cursors.py [--seed violet] [--family expressive] [--style dark]

Requires rsvg-convert (librsvg) and xcursorgen (xorg-xcursorgen).
"""

import argparse
import math
import os
import shutil
import subprocess
import sys
import tempfile

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from palette_lib import SEED_HEX  # noqa: E402

SIZES = [24, 32, 48, 64]
FPS = 12


# ---- geometry helpers (same names as the design's JS) ----------------------
def P(d, c=None):
    return {"t": "path", "a": {"d": d}, "c": c}


def L(d, w, c=None, **x):
    return {"t": "path", "a": {"d": d}, "w": w, "c": c, **x}


def C(cx, cy, r, c=None, **x):
    return {"t": "circle", "a": {"cx": cx, "cy": cy, "r": r}, "c": c, **x}


def R(x, y, w, h, rx, c=None):
    return {"t": "rect", "a": {"x": x, "y": y, "width": w, "height": h, "rx": rx}, "c": c}


def RING(cx, cy, r, w, c=None):
    return {"t": "circle", "a": {"cx": cx, "cy": cy, "r": r}, "w": w, "c": c}


ARROW = P("M5 3.5 L5 24 L10 19.5 L13.6 27.3 L17.2 25.7 L13.7 18 L20.5 18 Z")
UP, DN = P("M16 3 L21.5 9.5 H10.5 Z"), P("M16 29 L21.5 22.5 H10.5 Z")
LT, RT = P("M3 16 L9.5 10.5 V21.5 Z"), P("M29 16 L22.5 10.5 V21.5 Z")
BADGE = C(24, 24, 6.5, "acc")
NS = [L("M16 8 V24", 2.6), UP, DN]
SQB = R(17.5, 17.5, 13, 13, 4.5, "acc")

# [label, names (first = file name, rest = symlinks), hotspot x, y, elements, transform]
CURSORS = [
    ["Default", ["left_ptr", "default", "arrow", "top_left_arrow", "left_arrow"], 5, 3.5, [ARROW]],
    ["Link", ["hand2", "pointer", "hand1", "hand", "pointing_hand",
              "e29285e634086352946a0e7090d73106", "9d800788f1b08800ae810202380a0822"], 12.5, 3,
     [R(10, 3, 5, 15, 2.5), R(15, 10, 4.6, 9, 2.3), R(19.4, 11.5, 4.6, 8, 2.3), R(6, 15, 5, 8, 2.5), R(8, 13, 16, 15, 6)]],
    ["Text", ["xterm", "text", "ibeam"], 16, 16, [L("M12.5 6 H19.5 M12.5 26 H19.5 M16 6 V26", 2.2)]],
    ["Vertical text", ["vertical-text"], 16, 16, [L("M6 12.5 V19.5 M26 12.5 V19.5 M6 16 H26", 2.2)]],
    ["Busy", ["watch", "wait"], 16, 16, [RING(16, 16, 10, 4), L("M16 6 A10 10 0 0 1 26 16", 4, "acc", spin=(16, 16))]],
    ["Working", ["left_ptr_watch", "progress", "half-busy", "3ecb610c1bf2410f44200f48c40d3599",
                 "08e8e1c95fe2fc01f976f1e063a24ccd", "00000000000000020006000e7e9ffc3f"], 5, 3.5,
     [ARROW, RING(24, 24, 5, 2.8), L("M24 19 A5 5 0 0 1 29 24", 2.8, "acc", spin=(24, 24))]],
    ["Help", ["question_arrow", "help", "whats_this", "left_ptr_help",
              "d9ce0ab605698f320427677b458ad60b", "5c6cd98b3f3ebcb1f9c7f1c204630408"], 5, 3.5,
     [ARROW, BADGE, L("M21.7 22 Q21.7 19.8 24 19.8 Q26.2 19.8 26.2 21.6 Q26.2 23 24 23.8 V24.8", 1.7, "on", no=True),
      C(24, 27.3, 1.05, "on", no=True)]],
    ["Context menu", ["context-menu"], 5, 3.5,
     [ARROW, R(17.5, 16.5, 12, 13, 3, "acc"), L("M20.5 20.5 H26.5 M20.5 23 H26.5 M20.5 25.5 H24", 1.4, "on", no=True)]],
    ["Copy", ["copy", "dnd-copy", "1081e37283d90000800003c07f3ef6bf", "6407b0e94181790501fd1e167b474872"], 5, 3.5,
     [ARROW, BADGE, L("M24 20.6 V27.4 M20.6 24 H27.4", 2, "on", no=True)]],
    ["Alias", ["alias", "dnd-link", "link", "3085a0e285430894940527032f8b26df", "640fb0e74195791501fd1ed57b41487f"], 5, 3.5,
     [ARROW, BADGE, L("M21.2 27 V24.8 Q21.2 21.6 24.4 21.6 H26.6 M24.8 19.7 L26.8 21.6 L24.8 23.5", 1.7, "on", no=True)]],
    ["Not allowed", ["crossed_circle", "not-allowed", "forbidden", "circle", "no-drop", "dnd-no-drop",
                     "dnd-none", "03b6e0fcb3499374a867c041f52298f0"], 16, 16,
     [RING(16, 16, 9.5, 3.6, "danger"), L("M9.3 22.7 L22.7 9.3", 3.6, "danger")]],
    ["Move", ["fleur", "move", "size_all", "dnd-move", "4498f0e0c1937ffe01fd06f973665830",
              "9081237383d90e509aa00f00170e968f"], 16, 16, [L("M16 8 V24 M8 16 H24", 2.6), UP, DN, LT, RT]],
    ["All scroll", ["all-scroll"], 16, 16, [C(16, 16, 3), UP, DN, LT, RT]],
    ["Grab", ["openhand", "grab", "9141b49c8149039304290b508d208c40", "5aca4d189052212118709018842178c0"], 16, 16,
     [R(8, 6, 4.2, 12, 2.1), R(12.4, 4, 4.2, 13, 2.1), R(16.8, 5, 4.2, 12, 2.1), R(21.2, 8, 4, 10, 2),
      R(4.5, 14.5, 6.5, 4.6, 2.3), R(8, 12, 17.2, 15, 6)]],
    ["Grabbing", ["closedhand", "grabbing", "208530c400c041818281048008011002"], 16, 16,
     [R(9, 10, 4.2, 6.5, 2.1), R(13.2, 9, 4.2, 6.5, 2.1), R(17.4, 9, 4.2, 6.5, 2.1), R(21.4, 10, 3.8, 6.5, 1.9),
      R(8.5, 12.5, 16.7, 13.5, 6)]],
    ["Resize ns", ["sb_v_double_arrow", "ns-resize", "v_double_arrow", "size_ver", "n-resize", "s-resize",
                   "top_side", "bottom_side", "00008160000006810000408080010102"], 16, 16, NS],
    ["Resize ew", ["sb_h_double_arrow", "ew-resize", "h_double_arrow", "size_hor", "e-resize", "w-resize",
                   "left_side", "right_side", "028006030e0e7ebffc7f7070c0600140"], 16, 16, NS, "rotate(90 16 16)"],
    ["Resize nwse", ["bd_double_arrow", "nwse-resize", "size_fdiag", "nw-resize", "se-resize", "top_left_corner",
                     "bottom_right_corner", "c7088f0f3e6c8088236ef8e1e3e70000", "38c5dff7c7b8962045400281044508d2"],
     16, 16, NS, "rotate(-45 16 16)"],
    ["Resize nesw", ["fd_double_arrow", "nesw-resize", "size_bdiag", "ne-resize", "sw-resize", "top_right_corner",
                     "bottom_left_corner", "fcf1c3c7cd4491d801f1e1c78f100000", "50585d75b494802d0151028115016902"],
     16, 16, NS, "rotate(45 16 16)"],
    ["Column resize", ["split_h", "col-resize", "14fef782d02440884392942c11205230"], 16, 16,
     [L("M13.8 6 V26 M18.2 6 V26", 2.2), L("M4 16 H10 M22 16 H28", 2.4), P("M2.5 16 L7.5 11.5 V20.5 Z"),
      P("M29.5 16 L24.5 11.5 V20.5 Z")]],
    ["Row resize", ["split_v", "row-resize", "2870a09082c103050810ffdffffe0204"], 16, 16,
     [L("M13.8 6 V26 M18.2 6 V26", 2.2), L("M4 16 H10 M22 16 H28", 2.4), P("M2.5 16 L7.5 11.5 V20.5 Z"),
      P("M29.5 16 L24.5 11.5 V20.5 Z")], "rotate(90 16 16)"],
    ["Crosshair", ["cross", "crosshair", "tcross", "cross_reverse", "diamond_cross"], 16, 16,
     [L("M16 4 V12 M16 20 V28 M4 16 H12 M20 16 H28", 2.2), C(16, 16, 1.5)]],
    ["Cell", ["plus", "cell"], 16, 16, [P("M13 5 H19 V13 H27 V19 H19 V27 H13 V19 H5 V13 H13 Z")]],
    ["Zoom in", ["zoom-in"], 13, 13, [L("M19.5 19.5 L26.5 26.5", 4.4), C(13, 13, 9),
                                     L("M9.3 13 H16.7 M13 9.3 V16.7", 2.2, "on", no=True)]],
    ["Zoom out", ["zoom-out"], 13, 13, [L("M19.5 19.5 L26.5 26.5", 4.4), C(13, 13, 9),
                                       L("M9.3 13 H16.7", 2.2, "on", no=True)]],
    ["Draw", ["pencil", "draft"], 5, 27, [P("M5 27 L6.6 20.4 L20.8 6.2 L25.8 11.2 L11.6 25.4 Z"),
                                          P("M5 27 L6.6 20.4 L11.6 25.4 Z", "acc")]],
]

FAMS = {
    "classic": dict(arrow=ARROW, ow=1.5, round=0.6, lw=0, shadow=False, sq=False, morph=False),
    "soft": dict(arrow=P("M6 4.5 L6 24.2 L11.7 19.3 L19.6 19.3 Z"), ow=1.3, round=2.2, lw=0.3,
                 shadow=True, sq=False, morph=False),
    "expressive": dict(arrow=P("M5.5 4 L5.5 25 L11.8 19.8 L20.6 19.8 Z"), ow=1.4, round=3.2, lw=0.6,
                       shadow=True, sq=True, morph=True),
    "pebble": dict(arrow=P("M6 4.5 L11 25.5 L14 18 L21.8 15.4 Z"), ow=1.3, round=3.6, lw=0.5,
                   shadow=True, sq=True, morph=True),
}


def mix(h, t, a):
    return "#" + "".join(
        f"{round(int(h[i:i + 2], 16) * (1 - a) + int(t[i:i + 2], 16) * a):02x}" for i in (1, 3, 5)
    )


def colours(style, seed):
    s = SEED_HEX[seed]
    return {
        "dark": {"ink": "#1b1d22", "paper": "#ffffff", "acc": s, "on": "#ffffff", "danger": "#e5484d"},
        "light": {"ink": "#ffffff", "paper": "#1b1d22", "acc": s, "on": "#ffffff", "danger": "#e5484d"},
        "accent": {"ink": s, "paper": "#ffffff", "acc": "#1b1d22", "on": "#ffffff", "danger": "#e5484d"},
        "tonal": {"ink": mix(s, "#ffffff", 0.72), "paper": mix(s, "#000000", 0.62), "acc": s, "on": "#ffffff",
                  "danger": "#e5484d"},
    }[style]


def fam_els(cur, fam):
    label, els = cur[0], cur[4]
    els = [fam["arrow"] if e is ARROW else (SQB if e is BADGE and fam["sq"] else e) for e in els]
    if fam["morph"] and label == "Busy":
        els = [{"t": "rect", "a": {"x": 7.5, "y": 7.5, "width": 17, "height": 17, "rx": 8.5}, "c": "acc",
                "morph": (8.5, 3), "spin": (16, 16)}]
    if fam["morph"] and label == "Working":
        els = [fam["arrow"], {"t": "rect", "a": {"x": 19, "y": 19, "width": 10.5, "height": 10.5, "rx": 5.25},
                              "c": "acc", "morph": (5.25, 1.8), "spin": (24.25, 24.25)}]
    return els


def animation(els):
    """(duration in s, frame count) for an animated cursor, or None."""
    spinners = [e for e in els if e.get("spin")]
    if not spinners:
        return None
    dur = 1.6 if any(e.get("morph") for e in spinners) else 1.0
    return dur, max(2, round(dur * FPS))


def svg(cur, fam, col, t=0.0):
    """The cursor as SVG at animation phase t (0..1), per the design's cursorSvg()."""
    els = fam_els(cur, fam)

    def tag(e, fill, stroke, sw):
        a = dict(e["a"])
        if e.get("morph"):
            r0, r1 = e["morph"]  # rx animates r0 -> r1 -> r0 (linear SMIL values)
            a["rx"] = r0 + (r1 - r0) * (1 - abs(1 - 2 * t))
        attrs = " ".join(f'{k}="{v}"' for k, v in a.items())
        return (f'<{e["t"]} {attrs} fill="{fill}" stroke="{stroke}" stroke-width="{sw}" '
                f'stroke-linejoin="round" stroke-linecap="round"/>')

    def wrap(e, s):
        if not e.get("spin"):
            return s
        cx, cy = e["spin"]
        return f'<g transform="rotate({360 * t:.2f} {cx} {cy})">{s}</g>'

    outline = "".join(
        wrap(e, tag(e, "none", col["paper"], e["w"] + fam["lw"] + fam["ow"] * 2) if e.get("w")
             else tag(e, col["paper"], col["paper"], fam["round"] + fam["ow"] * 2))
        for e in els if not e.get("no"))
    ink = "".join(
        wrap(e, tag(e, "none", col[e.get("c") or "ink"], e["w"] + fam["lw"]) if e.get("w")
             else tag(e, col[e.get("c") or "ink"], col[e.get("c") or "ink"], fam["round"]))
        for e in els)
    if fam["shadow"]:
        outline = ('<defs><filter id="d" x="-40%" y="-40%" width="180%" height="180%">'
                   '<feDropShadow dx="0" dy="1.1" stdDeviation="1.1" flood-color="#000" flood-opacity="0.38"/>'
                   f'</filter></defs><g filter="url(#d)">{outline}</g>')
    body = outline + ink
    tr = cur[5] if len(cur) > 5 else None
    if tr:
        body = f'<g transform="{tr}">{body}</g>'
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="32" height="32" viewBox="0 0 32 32">{body}</svg>'


def hotspot(cur):
    """Hotspot on the 32 grid, rotated with the cursor's transform (design: rot())."""
    x, y = cur[2], cur[3]
    tr = cur[5] if len(cur) > 5 else None
    if not tr:
        return x, y
    a = math.radians(float(tr.split("(")[1].split()[0]))
    dx, dy = x - 16, y - 16
    return 16 + dx * math.cos(a) - dy * math.sin(a), 16 + dx * math.sin(a) + dy * math.cos(a)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default="iso/airootfs/usr/share/icons/Aedwen")
    ap.add_argument("--seed", default="violet", choices=SEED_HEX.keys())
    ap.add_argument("--family", default="expressive", choices=FAMS.keys())
    ap.add_argument("--style", default="dark", choices=["dark", "light", "accent", "tonal"])
    args = ap.parse_args()

    for tool in ("rsvg-convert", "xcursorgen"):
        if not shutil.which(tool):
            sys.exit(f"{tool} not found (install librsvg / xorg-xcursorgen)")

    fam, col = FAMS[args.family], colours(args.style, args.seed)
    cursors_dir = os.path.join(args.out, "cursors")
    shutil.rmtree(cursors_dir, ignore_errors=True)
    os.makedirs(cursors_dir)

    seen = set()
    with tempfile.TemporaryDirectory() as tmp:
        for cur in CURSORS:
            names = cur[1]
            dupes = seen.intersection(names)
            if dupes:
                sys.exit(f"cursor name(s) used twice: {', '.join(sorted(dupes))}")
            seen.update(names)

            anim = animation(fam_els(cur, fam))
            frames = [i / anim[1] for i in range(anim[1])] if anim else [0.0]
            delay = round(anim[0] * 1000 / anim[1]) if anim else 0
            hx, hy = hotspot(cur)
            config = []
            for fi, t in enumerate(frames):
                src = os.path.join(tmp, f"{names[0]}-{fi}.svg")
                with open(src, "w") as f:
                    f.write(svg(cur, fam, col, t))
                for size in SIZES:
                    png = os.path.join(tmp, f"{names[0]}-{size}-{fi}.png")
                    subprocess.run(["rsvg-convert", "-w", str(size), "-h", str(size), "-o", png, src], check=True)
                    line = f"{size} {round(hx * size / 32)} {round(hy * size / 32)} {png}"
                    config.append(line + (f" {delay}" if delay else ""))
            cfg = os.path.join(tmp, f"{names[0]}.cfg")
            with open(cfg, "w") as f:
                f.write("\n".join(config) + "\n")
            subprocess.run(["xcursorgen", cfg, os.path.join(cursors_dir, names[0])], check=True)
            for alias in names[1:]:
                os.symlink(names[0], os.path.join(cursors_dir, alias))

    with open(os.path.join(args.out, "index.theme"), "w") as f:
        f.write(f"""[Icon Theme]
Name=Aedwen
Comment=AedwenOS cursors · {args.family}, {args.style}, {args.seed} (generated by scripts/generate-cursors.py)
Inherits=breeze_cursors
""")

    print(f"Wrote {len(CURSORS)} cursors ({len(seen)} names, sizes {SIZES}) to {cursors_dir}")


if __name__ == "__main__":
    main()
