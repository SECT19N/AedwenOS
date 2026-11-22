#!/usr/bin/env python3
"""
Generate the AedwenOS default desktop wallpaper: a giant eagle watermark
on the --wall backdrop, matching the "Desktop - Material 3" design
(oklch(0.2 0.03 H) backdrop, oklch(0.38 0.1 H) eagle, "AedwenOS" wordmark
bottom-right), plus a light variant. The eagle is centred on the screen (the
design shifts it up-left; centred reads better).

Writes a Plasma "Image" wallpaper package: contents/images_dark/ (the dark
backdrop, used with a dark colour scheme) and contents/images/ (light), each
at 1920x1080, 2560x1440 and 3840x2160, so Plasma picks the sharpest size and
the right variant by itself. The ISO ships the violet one as
/usr/share/wallpapers/AedwenOS (the look-and-feel package's `defaults` file
sets `[Wallpaper] Image=AedwenOS`); aedwen-apps builds the accent-coloured
copy, AedwenOS-User, into ~/.local/share/wallpapers.

Usage:
    scripts/generate-desktop-wallpaper.py [--seed violet | --accent '#rrggbb']
                                          [--out DIR] [--id AedwenOS]

Requires python-cairo only (the eagle is tinted with a cairo mask).
"""
import argparse
import os
import sys

import cairo

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from palette_lib import DEFAULT_SEED, SEED_HEX, o, srgb_hex_to_oklch  # noqa: E402

SIZES = ((1920, 1080), (2560, 1440), (3840, 2160))
HERE = os.path.dirname(os.path.abspath(__file__))
# the eagle mark: in the repo, or where build.sh puts it for aedwen-apps
EAGLE_SRCS = (
    os.path.join(HERE, "..", "iso", "airootfs", "etc", "calamares", "branding", "aedwenos", "logo.png"),
    os.path.join(HERE, "eagle.png"),
)


def rgb(hexc):
    return tuple(int(hexc[i:i + 2], 16) / 255 for i in (1, 3, 5))


def artwork_box(img):
    """Bounding box (x0, y0, x1, y1) of the visible pixels of a cairo image:
    the logo file has padding, and not the same on every side."""
    w, h, stride = img.get_width(), img.get_height(), img.get_stride()
    data = bytes(img.get_data())  # ARGB32: alpha is byte 3 of each pixel
    xs, ys = [], []
    for y in range(h):
        row = data[y * stride:y * stride + w * 4][3::4]
        hit = [x for x, a in enumerate(row) if a > 16]
        if hit:
            xs += [hit[0], hit[-1]]
            ys.append(y)
    return min(xs), ys[0], max(xs) + 1, ys[-1] + 1


def render(path, w, h, hue, dark, eagle_img):
    s = h / 1080  # the design is drawn at 1080p
    if dark:
        wall, eagle, word = o(0.2, 0.03, hue), o(0.38, 0.1, hue), o(0.8, 0.025, hue)
    else:
        wall, eagle, word = o(0.93, 0.025, hue), o(0.84, 0.06, hue), o(0.42, 0.025, hue)

    surface = cairo.ImageSurface(cairo.FORMAT_ARGB32, w, h)
    ctx = cairo.Context(surface)
    ctx.set_source_rgb(*rgb(wall))
    ctx.paint()

    # Giant eagle watermark: the logo box is min(46vh, 520px) wide, placed so
    # the visible artwork (not the padded file) is centred on the screen.
    x0, y0, x1, y1 = artwork_box(eagle_img)
    k = min(h * 0.46, 520 * s) / eagle_img.get_width()
    ctx.save()
    ctx.translate(w / 2 - (x0 + x1) / 2 * k, h / 2 - (y0 + y1) / 2 * k)
    ctx.scale(k, k)
    ctx.set_source_rgb(*rgb(eagle))
    ctx.mask_surface(eagle_img, 0, 0)  # the logo's alpha, in the eagle tone
    ctx.restore()

    # "AedwenOS" wordmark, bottom-right.
    ctx.select_font_face("sans-serif", cairo.FONT_SLANT_NORMAL, cairo.FONT_WEIGHT_NORMAL)
    ctx.set_font_size(22 * s)
    ctx.set_source_rgba(*rgb(word), 0.85)
    text = "A E D W E N O S"
    ext = ctx.text_extents(text)
    ctx.move_to(w - ext.width - 48 * s, h - 96 * s)
    ctx.show_text(text)

    os.makedirs(os.path.dirname(path), exist_ok=True)
    surface.write_to_png(path)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--seed", default=DEFAULT_SEED, choices=SEED_HEX.keys())
    ap.add_argument("--accent", help="seed colour as #rrggbb (overrides --seed)")
    ap.add_argument("--id", default="AedwenOS", help="wallpaper package id / name")
    ap.add_argument("--out", default="iso/airootfs/usr/share/wallpapers/AedwenOS")
    args = ap.parse_args()

    hexc = args.accent or SEED_HEX[args.seed]
    hue = srgb_hex_to_oklch(hexc)[2]

    src = next((p for p in EAGLE_SRCS if os.path.exists(p)), None)
    if src is None:
        sys.exit("no eagle logo found (calamares branding logo.png or eagle.png)")
    eagle_img = cairo.ImageSurface.create_from_png(src)

    for dark, sub in ((True, "images_dark"), (False, "images")):
        for w, h in SIZES:
            render(os.path.join(args.out, "contents", sub, f"{w}x{h}.png"), w, h, hue, dark, eagle_img)

    with open(os.path.join(args.out, "metadata.json"), "w") as f:
        f.write(f"""{{
    "KPlugin": {{
        "Id": "{args.id}",
        "Name": "AedwenOS"
    }}
}}
""")
    print(f"Wrote {args.out} (accent {hexc}; {len(SIZES)} sizes, dark + light)")


if __name__ == "__main__":
    main()
