#!/usr/bin/env python3
"""
Generate the AedwenOS Plymouth boot-splash loader: the Material 3 Expressive
loading indicator in the seed's primary colour, the same one the shell draws
(org.aedwen.ui MorphShape).

The sequence and timing are Compose's indeterminate LoadingIndicator
(scripts/m3_shapes.py ports the shapes from androidx):

    soft burst -> 9-sided cookie -> pentagon -> pill -> sunny
    -> 4-sided cookie -> oval -> (soft burst)

There is one morph per 650 ms, driven by a spring (damping 0.6,
stiffness 200). Plymouth refreshes at 50 Hz, so a morph is 32 frames
(640 ms).

Plymouth's script module can't draw vectors, so the morphs are pre-rendered
as transparent PNG frames. The rotation is not baked in: aedwen.script turns
each frame by the spring's 90 degrees per morph (the turn[] table written
here, overshoot included), the quarter it has reached, and a steady
360 degrees per 4666 ms. That keeps the loop to 7 morphs (224 frames).
Like Compose, each frame is centred on its own bounds before rotating, and
the sequence is scaled so no shape clips its square while it turns.

It also rewrites the generated block of aedwen.script (num_frames,
frames_per_morph, turn[]).

Usage:
    scripts/generate-plymouth-assets.py [--seed violet | --hue 295] [--size 80]
                                        [--out DIR] [--script FILE]

Requires python-cairo (pacman: python-cairo). The AedwenOS appearance tool
runs this as root, with --hue, to recolour the boot screen.
"""

import argparse
import glob
import math
import os
import re
import sys
import tempfile

import cairo

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import m3_shapes as m  # noqa: E402
from palette_lib import DEFAULT_SEED, SEEDS, palette  # noqa: E402

REFRESH_HZ = 50
FRAMES_PER_MORPH = 32
SAMPLES = 240


def hex_to_rgb01(hex_color):
    hex_color = hex_color.lstrip("#")
    return tuple(int(hex_color[i : i + 2], 16) / 255 for i in (0, 2, 4))


def frames():
    """(points in the unit box, centred on their bounds) per frame, and the
    spring turn in radians per frame of a morph."""
    shapes = []
    prev = None
    for n in m.LOADER_SEQUENCE:
        cur = m.sample(m.SHAPES[n], SAMPLES)
        if prev is not None:
            cur = m.align(prev, cur)
        shapes.append(cur)
        prev = cur
    closing = m.align(shapes[-1], shapes[0])

    out = []
    turn = []
    for k in range(FRAMES_PER_MORPH):
        turn.append(math.radians(90 * m.spring(k * 1000 / REFRESH_HZ)))
    for i, a in enumerate(shapes):
        b = closing if i == len(shapes) - 1 else shapes[i + 1]
        for k in range(FRAMES_PER_MORPH):
            p = max(0.0, min(1.0, m.spring(k * 1000 / REFRESH_HZ)))
            pts = m.morph(a, b, p)
            xs, ys = [q[0] for q in pts], [q[1] for q in pts]
            cx, cy = (min(xs) + max(xs)) / 2, (min(ys) + max(ys)) / 2
            out.append([(q[0] - cx, q[1] - cy) for q in pts])
    return out, turn


def draw_frame(path, size, color01, pts):
    surface = cairo.ImageSurface(cairo.FORMAT_ARGB32, size, size)
    ctx = cairo.Context(surface)
    # the shape fills the frame as far as it can without clipping while it
    # turns (Compose's calculateScaleFactor); the KSplash MorphShape scales
    # the same way, so boot -> login looks identical
    scale = size * m.loader_scale() / m.ACTIVE_SCALE
    ctx.translate(size / 2, size / 2)
    for i, (x, y) in enumerate(pts):
        (ctx.move_to if i == 0 else ctx.line_to)(x * scale, y * scale)
    ctx.close_path()
    ctx.set_source_rgb(*color01)
    ctx.fill()
    surface.write_to_png(path)


def update_script(script_path, total, turn):
    with open(script_path) as f:
        src = f.read()
    block = (
        "//@generated-begin\n"
        f"loader.num_frames = {total};\n"
        f"loader.frames_per_morph = {FRAMES_PER_MORPH};\n"
        + "".join(f"loader.turn[{k}] = {t:.5f};\n" for k, t in enumerate(turn))
        + "//@generated-end"
    )
    new, count = re.subn(r"//@generated-begin.*?//@generated-end", block, src, flags=re.S)
    if count != 1:
        sys.exit(f"could not find the //@generated-begin/end block in {script_path}")
    tmp = script_path + ".tmp"
    with open(tmp, "w") as f:
        f.write(new)
    os.replace(tmp, script_path)


def main():
    theme = "iso/airootfs/usr/share/plymouth/themes/aedwen"
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default=f"{theme}/loader")
    ap.add_argument("--script", default=f"{theme}/aedwen.script")
    ap.add_argument("--size", type=int, default=80)
    g = ap.add_mutually_exclusive_group()
    g.add_argument("--seed", choices=SEEDS.keys())
    g.add_argument("--hue", type=int, help="custom accent hue, 0-359")
    args = ap.parse_args()

    if args.hue is not None:
        if not 0 <= args.hue <= 359:
            sys.exit("--hue must be 0..359")
        H = args.hue
    else:
        H = SEEDS[args.seed or DEFAULT_SEED]
    color = hex_to_rgb01(palette(H, dark=True, expressive=True)["primary"])

    pts, turn = frames()

    # render into a temp dir first, then swap: a failure leaves the old
    # frames in place
    parent = os.path.dirname(os.path.abspath(args.out))
    os.makedirs(parent, exist_ok=True)
    tmp = tempfile.mkdtemp(prefix=".loader-", dir=parent)
    for i, p in enumerate(pts):
        draw_frame(os.path.join(tmp, f"loader-{i}.png"), args.size, color, p)
    os.makedirs(args.out, exist_ok=True)
    for old in glob.glob(os.path.join(args.out, "loader-*.png")):
        os.remove(old)
    for f in os.listdir(tmp):
        os.replace(os.path.join(tmp, f), os.path.join(args.out, f))
    os.rmdir(tmp)

    update_script(args.script, len(pts), turn)
    print(f"Wrote {len(pts)} loader frames ({args.size}x{args.size}) to {args.out}")


if __name__ == "__main__":
    main()
