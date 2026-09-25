#!/usr/bin/env python3
"""
Generate the AedwenOS Limine boot-menu wallpaper: a single rounded card,
transparent everywhere else so Limine's `backdrop` colour shows through
around it -- matching the "Boot, install, first run" section of the
AedwenOS System Surfaces design ("the rounded card is part of the
wallpaper, centred on a solid backdrop").

The card itself is intentionally plain (solid fill, rounded corners): the
menu entries, branding string and help text are drawn by Limine itself on
top, at boot time, from limine.conf -- see aedwen-install and
etc/calamares/modules/shellprocess-postinstall.conf for the matching
`wallpaper`/`backdrop`/`interface_*`/`term_*` keys.

Usage:
    scripts/generate-limine-wallpaper.py [--seed violet]

Requires python-cairo.
"""

import argparse
import os
import sys

import cairo

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from palette_lib import DEFAULT_SEED, SEEDS, palette  # noqa: E402

CARD_W, CARD_H, RADIUS = 1000, 600, 28


def hex_to_rgba(hex_color, alpha=1.0):
    hex_color = hex_color.lstrip("#")
    r, g, b = (int(hex_color[i : i + 2], 16) / 255 for i in (0, 2, 4))
    return r, g, b, alpha


def rounded_rect(ctx, x, y, w, h, r):
    ctx.new_sub_path()
    ctx.arc(x + w - r, y + r, r, -3.14159 / 2, 0)
    ctx.arc(x + w - r, y + h - r, r, 0, 3.14159 / 2)
    ctx.arc(x + r, y + h - r, r, 3.14159 / 2, 3.14159)
    ctx.arc(x + r, y + r, r, 3.14159, 3 * 3.14159 / 2)
    ctx.close_path()


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--seed", default=DEFAULT_SEED, choices=SEEDS.keys())
    ap.add_argument(
        "--out", default="iso/airootfs/usr/share/limine/aedwen-wallpaper.png"
    )
    args = ap.parse_args()

    H = SEEDS[args.seed]
    p = palette(H, dark=True, expressive=True)

    surface = cairo.ImageSurface(cairo.FORMAT_ARGB32, CARD_W, CARD_H)
    ctx = cairo.Context(surface)
    rounded_rect(ctx, 0, 0, CARD_W, CARD_H, RADIUS)
    ctx.set_source_rgba(*hex_to_rgba(p["sc-high"], 0.96))
    ctx.fill_preserve()
    ctx.set_source_rgba(*hex_to_rgba(p["outline-v"], 0.6))
    ctx.set_line_width(1.5)
    ctx.stroke()

    os.makedirs(os.path.dirname(args.out), exist_ok=True)
    surface.write_to_png(args.out)
    print(f"Wrote {args.out} ({CARD_W}x{CARD_H}, seed={args.seed})")
    print(f"backdrop (surface): {p['surface'].lstrip('#')}")
    print(f"term_foreground (on-s): {p['on-s'].lstrip('#')}")
    print(f"interface_branding_colour (primary): {p['primary'].lstrip('#')}")


if __name__ == "__main__":
    main()
