#!/usr/bin/env python3
"""
Generate the AedwenOS Plymouth boot-splash loader frames: a morphing
rounded-square/circle shape in the seed's primary colour, approximating the
`aeMorph` CSS keyframe animation from the AedwenOS System Surfaces design
(circle -> squircle -> rounded square -> squircle -> circle, with a
quarter-turn of rotation and a slight scale dip at each squircle step).

Plymouth's script module can't run CSS, so this pre-renders the loop as a
sequence of transparent PNG frames that aedwen.script cycles through.

Usage:
    scripts/generate-plymouth-assets.py [--frames 32] [--size 120]

Requires python-cairo (pacman: python-cairo).
"""
import argparse
import math
import os
import sys

import cairo

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from palette_lib import SEEDS, palette, DEFAULT_SEED  # noqa: E402

# Keyframes from the design's @keyframes aeMorph, sampled at 0/25/50/75/100%:
# (corner-radius fraction of half-size, rotation degrees, scale)
KEYFRAMES = [
    (0.50, 0, 1.00),
    (0.34, 90, 0.88),
    (0.30, 180, 1.00),
    (0.34, 270, 0.88),
    (0.50, 360, 1.00),
]


def lerp(a, b, t):
    return a + (b - a) * t


def sample(progress):
    """progress in [0,1) across the whole 4-segment loop."""
    seg_f = progress * 4
    seg = min(int(seg_f), 3)
    t = seg_f - seg
    r0, rot0, s0 = KEYFRAMES[seg]
    r1, rot1, s1 = KEYFRAMES[seg + 1]
    # ease (matches the design's springy cubic-bezier(.34,1.45,.55,1) in spirit)
    t_eased = t * t * (3 - 2 * t)
    return lerp(r0, r1, t_eased), lerp(rot0, rot1, t_eased), lerp(s0, s1, t_eased)


def hex_to_rgb01(hex_color):
    hex_color = hex_color.lstrip("#")
    return tuple(int(hex_color[i:i + 2], 16) / 255 for i in (0, 2, 4))


def draw_frame(path, size, color01, radius_frac, rotation_deg, scale):
    surface = cairo.ImageSurface(cairo.FORMAT_ARGB32, size, size)
    ctx = cairo.Context(surface)
    ctx.translate(size / 2, size / 2)
    ctx.rotate(math.radians(rotation_deg))
    ctx.scale(scale, scale)

    box = size * 0.72
    half = box / 2
    r = max(0.001, radius_frac) * half

    # rounded-rect path centred on the origin
    ctx.new_sub_path()
    ctx.arc(half - r, -half + r, r, -math.pi / 2, 0)
    ctx.arc(half - r, half - r, r, 0, math.pi / 2)
    ctx.arc(-half + r, half - r, r, math.pi / 2, math.pi)
    ctx.arc(-half + r, -half + r, r, math.pi, 3 * math.pi / 2)
    ctx.close_path()

    ctx.set_source_rgb(*color01)
    ctx.fill()
    surface.write_to_png(path)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default="iso/airootfs/usr/share/plymouth/themes/aedwen/loader")
    ap.add_argument("--frames", type=int, default=32)
    ap.add_argument("--size", type=int, default=120)
    ap.add_argument("--seed", default=DEFAULT_SEED)
    args = ap.parse_args()

    H = SEEDS[args.seed]
    p = palette(H, dark=True, expressive=True)
    color = hex_to_rgb01(p["primary"])

    os.makedirs(args.out, exist_ok=True)
    for i in range(args.frames):
        progress = i / args.frames
        r, rot, s = sample(progress)
        path = os.path.join(args.out, f"loader-{i}.png")
        draw_frame(path, args.size, color, r, rot, s)

    print(f"Wrote {args.frames} loader frames ({args.size}x{args.size}) to {args.out}")


if __name__ == "__main__":
    main()
