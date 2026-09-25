#!/usr/bin/env python3
"""
Generate the AedwenOS default desktop wallpaper: a giant eagle watermark
on the --wall backdrop, matching the "Desktop - Material 3" design
(oklch(0.2 0.03 H) backdrop, oklch(0.38 0.1 H) eagle, shifted up-left of
centre, "AedwenOS" wordmark bottom-right).

Packages it as a real Plasma "Image" wallpaper plugin
(/usr/share/wallpapers/AedwenOS/contents/images/1920x1080.png), referenced
by the org.kde.aedwen.desktop look-and-feel package's `defaults` file
(`[Wallpaper] Image=AedwenOS`).

Usage:
    scripts/generate-desktop-wallpaper.py [--seed violet]

Requires python-cairo and rsvg-convert (to rasterize the eagle mask).
"""
import argparse
import os
import subprocess
import sys
import tempfile

import cairo

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from palette_lib import SEEDS, DEFAULT_SEED, o  # noqa: E402

W, H_PX = 1920, 1080
EAGLE_SRC = "iso/airootfs/etc/calamares/branding/aedwenos/logo.png"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--seed", default=DEFAULT_SEED, choices=SEEDS.keys())
    ap.add_argument("--out", default="iso/airootfs/usr/share/wallpapers/AedwenOS")
    args = ap.parse_args()

    hue = SEEDS[args.seed]
    wall_hex = o(0.2, 0.03, hue)
    eagle_hex = o(0.38, 0.1, hue)

    images_dir = os.path.join(args.out, "contents", "images")
    os.makedirs(images_dir, exist_ok=True)
    out_png = os.path.join(images_dir, "1920x1080.png")

    # Recolor the eagle mark to the eagle tone (same alpha-mask technique
    # used for the Plymouth logo -- see generate-plymouth-assets.py).
    with tempfile.TemporaryDirectory() as td:
        eagle_tinted = os.path.join(td, "eagle.png")
        subprocess.run(
            ["magick", EAGLE_SRC, "-fill", eagle_hex, "-colorize", "100", eagle_tinted],
            check=True,
        )
        eagle_img = cairo.ImageSurface.create_from_png(eagle_tinted)

    surface = cairo.ImageSurface(cairo.FORMAT_ARGB32, W, H_PX)
    ctx = cairo.Context(surface)

    r, g, b = (int(wall_hex[i:i + 2], 16) / 255 for i in (1, 3, 5))
    ctx.set_source_rgb(r, g, b)
    ctx.paint()

    # Giant eagle watermark: ~46% of the shorter dimension, shifted up-left
    # of centre (matches translate(-30%,-54%) on a centred min(46vh,520px) box).
    size = min(int(H_PX * 0.9), 900)
    ex = W / 2 - size * 0.8
    ey = H_PX / 2 - size * 1.04
    ctx.save()
    ctx.translate(ex, ey)
    scale = size / eagle_img.get_width()
    ctx.scale(scale, scale)
    ctx.set_source_surface(eagle_img, 0, 0)
    ctx.paint_with_alpha(1.0)
    ctx.restore()

    # "AedwenOS" wordmark, bottom-right.
    ctx.select_font_face("sans-serif", cairo.FONT_SLANT_NORMAL, cairo.FONT_WEIGHT_NORMAL)
    ctx.set_font_size(22)
    on_sv_hex = o(0.8, 0.025, hue)
    r2, g2, b2 = (int(on_sv_hex[i:i + 2], 16) / 255 for i in (1, 3, 5))
    ctx.set_source_rgba(r2, g2, b2, 0.85)
    text = "A E D W E N O S"
    extents = ctx.text_extents(text)
    ctx.move_to(W - extents.width - 48, H_PX - 96)
    ctx.show_text(text)

    surface.write_to_png(out_png)

    with open(os.path.join(args.out, "metadata.json"), "w") as f:
        f.write("""{
    "KPlugin": {
        "Id": "AedwenOS",
        "Name": "AedwenOS"
    }
}
""")

    print(f"Wrote {out_png} ({W}x{H_PX}, seed={args.seed})")
    print(f"wall backdrop: {wall_hex}, eagle: {eagle_hex}")


if __name__ == "__main__":
    main()
