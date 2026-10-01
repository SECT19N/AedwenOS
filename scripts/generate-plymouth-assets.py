#!/usr/bin/env python3
"""
Generate the AedwenOS Plymouth boot-splash loader frames: a shape-morphing
loading indicator in the seed's primary colour, in the style of the Material 3
Expressive loading indicator. It cycles circle -> soft burst -> 9-lobe cookie
-> pentagon -> pill -> sunny -> 4-lobe cookie -> back to circle, spinning
continuously, with a springy overshoot (the design's cubic-bezier(.34,1.45,.55,1))
and a slight scale dip on each morph.

Every shape is a polar radius function r(theta), sampled at the same angles,
so morphing between two shapes is a per-angle interpolation of radii. Shapes
are normalised to equal area so the indicator doesn't visibly grow or shrink
between them.

Plymouth's script module can't draw vectors, so this pre-renders the loop as
transparent PNG frames and rewrites `loader.num_frames` in aedwen.script to
match. The script advances one frame per refresh (~50 Hz).

Usage:
    scripts/generate-plymouth-assets.py [--frames-per-shape 28] [--size 120]

Requires python-cairo (pacman: python-cairo).
"""

import argparse
import glob
import math
import os
import re
import sys

import cairo

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from palette_lib import DEFAULT_SEED, SEEDS, palette  # noqa: E402

SAMPLES = 360
THETAS = [2 * math.pi * i / SAMPLES for i in range(SAMPLES)]


def lobes(n, depth):
    """Scalloped 'cookie'/'burst' outline with n rounded lobes."""
    return lambda t: 1 + depth * math.cos(n * t)


def polygon(n, corner_deg):
    """Regular n-gon (vertex at the top) with rounded corners: the sharp
    outline averaged over a corner_deg-wide window of angles."""
    seg = 2 * math.pi / n
    half = math.radians(corner_deg) / 2
    taps = 15

    def sharp(t):
        local = (t - math.pi / 2) % seg - seg / 2
        return math.cos(math.pi / n) / math.cos(local)

    def r(t):
        return sum(sharp(t - half + 2 * half * k / (taps - 1)) for k in range(taps)) / taps
    return r


def superellipse(a, b, exp):
    """Pill/stadium-like outline: |x/a|^exp + |y/b|^exp = 1."""
    def r(t):
        c, s = abs(math.cos(t)), abs(math.sin(t))
        return ((c / a) ** exp + (s / b) ** exp) ** (-1 / exp)
    return r


def sunny(n, depth):
    """Pointier burst: lobes sharpened with a power curve."""
    return lambda t: 1 + depth * (abs(math.cos(n * t / 2)) ** 3 * 2 - 1)


SHAPES = [
    lambda t: 1.0,                 # circle
    lobes(8, 0.10),                # soft burst
    lobes(9, 0.07),                # 9-lobe cookie
    polygon(5, 30),                # rounded pentagon
    superellipse(1.0, 0.62, 3.2),  # pill
    sunny(8, 0.12),                # sunny
    lobes(4, 0.11),                # 4-lobe cookie
]


def normalised(shape):
    """Sample a shape and scale it to the area of the unit circle."""
    radii = [shape(t) for t in THETAS]
    area = 0.5 * sum(r * r for r in radii) * (2 * math.pi / SAMPLES)
    k = math.sqrt(math.pi / area)
    return [r * k for r in radii]


def cubic_bezier(x1, y1, x2, y2):
    """CSS cubic-bezier timing function (y may overshoot past 1)."""
    def bez(t, p1, p2):
        u = 1 - t
        return 3 * u * u * t * p1 + 3 * u * t * t * p2 + t ** 3

    def ease(x):
        lo, hi = 0.0, 1.0
        for _ in range(40):  # bisection on x(t) -- monotonic for these params
            mid = (lo + hi) / 2
            if bez(mid, x1, x2) < x:
                lo = mid
            else:
                hi = mid
        return bez((lo + hi) / 2, y1, y2)
    return ease


SPRING = cubic_bezier(0.34, 1.45, 0.55, 1)
HOLD = 0.30        # fraction of each step the shape rests before morphing
SCALE_DIP = 0.90   # scale at the middle of a morph
SPIN_PER_STEP = 140  # degrees of rotation per shape step


def sample(radii_sets, frame, frames_per_shape):
    """Radii, rotation (deg) and scale for one frame of the loop."""
    n = len(radii_sets)
    step, sub = divmod(frame, frames_per_shape)
    p = sub / frames_per_shape
    m = 0.0 if p < HOLD else (p - HOLD) / (1 - HOLD)
    t = SPRING(m)
    a, b = radii_sets[step], radii_sets[(step + 1) % n]
    radii = [max(0.2, ra + (rb - ra) * t) for ra, rb in zip(a, b)]
    # steady spin plus a spring-eased kick during the morph
    rotation = SPIN_PER_STEP * (step + 0.4 * p + 0.6 * t)
    scale = 1 - (1 - SCALE_DIP) * math.sin(math.pi * m)
    return radii, rotation, scale


def hex_to_rgb01(hex_color):
    hex_color = hex_color.lstrip("#")
    return tuple(int(hex_color[i : i + 2], 16) / 255 for i in (0, 2, 4))


def draw_frame(path, size, color01, radii, rotation_deg, scale, unit):
    surface = cairo.ImageSurface(cairo.FORMAT_ARGB32, size, size)
    ctx = cairo.Context(surface)
    ctx.translate(size / 2, size / 2)
    ctx.rotate(math.radians(rotation_deg))
    ctx.scale(scale * unit, scale * unit)

    for i, (t, r) in enumerate(zip(THETAS, radii)):
        x, y = r * math.cos(t), r * math.sin(t)
        (ctx.move_to if i == 0 else ctx.line_to)(x, y)
    ctx.close_path()

    ctx.set_source_rgb(*color01)
    ctx.fill()
    surface.write_to_png(path)


def update_script(script_path, total):
    with open(script_path) as f:
        src = f.read()
    new, count = re.subn(r"loader\.num_frames = \d+;", f"loader.num_frames = {total};", src)
    if count != 1:
        sys.exit(f"could not find 'loader.num_frames = N;' in {script_path}")
    with open(script_path, "w") as f:
        f.write(new)


def main():
    theme = "iso/airootfs/usr/share/plymouth/themes/aedwen"
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default=f"{theme}/loader")
    ap.add_argument("--script", default=f"{theme}/aedwen.script")
    ap.add_argument("--frames-per-shape", type=int, default=28)
    ap.add_argument("--size", type=int, default=120)
    ap.add_argument("--seed", default=DEFAULT_SEED)
    args = ap.parse_args()

    H = SEEDS[args.seed]
    p = palette(H, dark=True, expressive=True)
    color = hex_to_rgb01(p["primary"])

    radii_sets = [normalised(s) for s in SHAPES]
    # Fit the largest radius any frame can reach (incl. spring overshoot,
    # ~1.2x the biggest step) inside the frame with a little margin.
    peak = max(max(r) for r in radii_sets) * 1.2
    unit = (args.size / 2 - 2) / peak

    os.makedirs(args.out, exist_ok=True)
    for old in glob.glob(os.path.join(args.out, "loader-*.png")):
        os.remove(old)

    total = len(SHAPES) * args.frames_per_shape
    for i in range(total):
        radii, rot, s = sample(radii_sets, i, args.frames_per_shape)
        draw_frame(os.path.join(args.out, f"loader-{i}.png"),
                   args.size, color, radii, rot, s, unit)

    update_script(args.script, total)
    print(f"Wrote {total} loader frames ({args.size}x{args.size}) to {args.out}")


if __name__ == "__main__":
    main()
