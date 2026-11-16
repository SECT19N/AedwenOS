#!/usr/bin/env python3
"""
Generate the AedwenOS Limine boot menu: the wallpaper and the global
limine.conf options (System Surfaces design, "Bootloader · Limine").

The design draws a dark backdrop with a rounded card (72 % x 88 %, 1 px
inner border). At the top of the card sit the eagle and "AedwenOS" in the
primary colour, then a divider. Below are the entries, with the selected
one filled in primary, and "Booting in 3" centred at the bottom.

Limine can only print fixed-width text, so the picture is split:

- In the wallpaper (1920x1080, stretched): the backdrop, the card, its
  border, the eagle, the "AedwenOS" wordmark (Roboto Mono SemiBold) and the
  divider.
- Drawn by Limine, inside the card: the entries, centred; the entry
  comment; and the countdown, centred near the bottom of the card.
  `term_margin` keeps the terminal inside the card.

Colours come from the design's values at its hues. The card, border and
text use the design's lightness and chroma at the seed hue, so another
accent gives the same card, tinted.

- `term_foreground` is the primary colour. Limine highlights the selected
  entry in reverse video, so the selected entry becomes a primary bar with
  dark text, as in the design. The other entries are drawn in primary as
  well, since reverse video ties the two together.
- The countdown uses the dimmed text colour, with its number in primary
  (`interface_help_colour[_bright]`).
- Entry comments print in the terminal's cyan, which the palette sets to the
  dimmed text colour.

It also writes usr/share/limine/aedwen-limine.conf: the global options both
boot menus start from. Those are the installed system's
(aedwen-bootloader-setup.sh appends its entries) and the live ISO's
(scripts/limine-live-esp.sh).

Usage:
    scripts/generate-limine-wallpaper.py [--seed violet | --hue 295]
                                         [--out PNG] [--conf FILE]
                                         [--eagle PNG]

Requires python-cairo, and Roboto Mono for the wordmark (ttf-roboto-mono;
the design's font, which cairo falls back from to any monospace). The AedwenOS
appearance tool runs this as root, with --hue, to recolour the menu.
"""

import argparse
import math
import os
import sys

import cairo

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from palette_lib import DEFAULT_SEED, SEEDS, o, palette  # noqa: E402

W, H = 1920, 1080
# design card: 72 % x 88 % of the screen, 16 px radius at the design's
# ~640 px preview width (x3 here)
CARD_W, CARD_H = round(W * 0.72), round(H * 0.88)
RADIUS = 44
# Limine's terminal starts this far in from every screen edge. Text is
# centred inside it, and the countdown sits two rows from its bottom. 96
# keeps both inside the card from 768 px tall screens up (the card's
# top/bottom margin is 6 % of the height when stretched).
TERM_MARGIN = 96
# header, in wallpaper pixels from the card's top edge
HEADER_Y = 64
EAGLE = 44
WORDMARK_PX = 34
DIVIDER_Y = 140


def rgb(hex_color, alpha=1.0):
    hex_color = hex_color.lstrip("#")
    return tuple(int(hex_color[i : i + 2], 16) / 255 for i in (0, 2, 4)) + (alpha,)


def colours(H_):
    """The design's Limine colours at hue H_. For violet these are exactly
    the design's #16141d / #2a2633 / #e6e1ee / #a8a2b4; the backdrop
    stays the design's neutral #0b0c0f."""
    return {
        "backdrop": "#0b0c0f",
        "card": o(0.1979, 0.0181, H_),
        "border": o(0.2786, 0.0242, H_ + 4),
        "text": o(0.9175, 0.0182, H_ + 8),
        "dim": o(0.723, 0.0266, H_ + 6),
        "primary": palette(H_, dark=True, expressive=True)["primary"],
        "on-primary": palette(H_, dark=True, expressive=True)["on-primary"],
    }


def rounded_rect(ctx, x, y, w, h, r):
    ctx.new_sub_path()
    ctx.arc(x + w - r, y + r, r, -math.pi / 2, 0)
    ctx.arc(x + w - r, y + h - r, r, 0, math.pi / 2)
    ctx.arc(x + r, y + h - r, r, math.pi / 2, math.pi)
    ctx.arc(x + r, y + r, r, math.pi, 3 * math.pi / 2)
    ctx.close_path()


def draw(path, c, eagle_png):
    surface = cairo.ImageSurface(cairo.FORMAT_RGB24, W, H)
    ctx = cairo.Context(surface)
    ctx.set_source_rgba(*rgb(c["backdrop"]))
    ctx.paint()

    x, y = (W - CARD_W) / 2, (H - CARD_H) / 2
    rounded_rect(ctx, x, y, CARD_W, CARD_H, RADIUS)
    ctx.set_source_rgba(*rgb(c["card"]))
    ctx.fill()
    # 1 px inset border (design), 1.5 px at this scale
    rounded_rect(ctx, x + 0.75, y + 0.75, CARD_W - 1.5, CARD_H - 1.5, RADIUS - 0.75)
    ctx.set_line_width(1.5)
    ctx.set_source_rgba(*rgb(c["border"]))
    ctx.stroke()

    # header: eagle + wordmark, centred together
    ctx.select_font_face("Roboto Mono", cairo.FONT_SLANT_NORMAL, cairo.FONT_WEIGHT_BOLD)
    ctx.set_font_size(WORDMARK_PX)
    word = "AedwenOS"
    ext = ctx.text_extents(word)
    gap = 14
    total = EAGLE + gap + ext.x_advance
    hx = (W - total) / 2
    cy = y + HEADER_Y
    if eagle_png and os.path.exists(eagle_png):
        mask = cairo.ImageSurface.create_from_png(eagle_png)
        s = EAGLE / max(mask.get_width(), mask.get_height())
        ctx.save()
        ctx.translate(hx, cy - EAGLE / 2)
        ctx.scale(s, s)
        ctx.set_source_rgba(*rgb(c["primary"]))
        ctx.mask_surface(mask, 0, 0)
        ctx.restore()
    else:
        total = ext.x_advance
        hx = (W - total) / 2 - EAGLE - gap
    ctx.set_source_rgba(*rgb(c["primary"]))
    ctx.move_to(hx + EAGLE + gap, cy - (ext.y_bearing + ext.height / 2))
    ctx.show_text(word)

    # divider across the card (design: 1 px, border colour)
    ctx.set_source_rgba(*rgb(c["border"]))
    ctx.rectangle(x + 1.5, y + DIVIDER_Y, CARD_W - 3, 1.5)
    ctx.fill()

    tmp = path + ".tmp"
    surface.write_to_png(tmp)
    os.replace(tmp, path)


def conf_text(c):
    hx = lambda k: c[k].lstrip("#")  # noqa: E731
    # black, red, green, brown, blue, magenta, cyan, gray; cyan carries the
    # entry comments, so it is the dimmed text colour
    palette8 = [hx("card"), "ff9b93", "a6d6a0", "e7c27a", hx("primary"), hx("primary"), hx("dim"), hx("text")]
    return (
        "# AedwenOS boot menu look -- generated by scripts/generate-limine-wallpaper.py;\n"
        "# do not edit by hand (the Appearance settings rewrite it for a new accent).\n"
        "# Boot entries are appended after this by the installer / build.sh.\n"
        "timeout: 3\n"
        "wallpaper: boot():/limine-wallpaper.png\n"
        "wallpaper_style: stretched\n"
        f"backdrop: {hx('backdrop')}\n"
        f"interface_resolution: {W}x{H}\n"
        "interface_branding:\n"
        "interface_help_hidden: yes\n"
        f"interface_help_colour: {hx('dim')}\n"
        f"interface_help_colour_bright: {hx('primary')}\n"
        f"term_foreground: {hx('primary')}\n"
        f"term_foreground_bright: {hx('text')}\n"
        "term_background: ff000000\n"
        f"term_background_bright: {hx('card')}\n"
        f"term_palette: {';'.join(palette8)}\n"
        f"term_margin: {TERM_MARGIN}\n"
        "term_margin_gradient: 0\n"
        # design: 11.5 px type on a ~640 px preview, about 2x Limine's 8x16
        "term_font_scale: 2x2\n"
    )


def main():
    ap = argparse.ArgumentParser()
    g = ap.add_mutually_exclusive_group()
    g.add_argument("--seed", choices=SEEDS.keys())
    g.add_argument("--hue", type=int, help="custom accent hue, 0-359")
    ap.add_argument("--out", default="iso/airootfs/usr/share/limine/aedwen-wallpaper.png")
    ap.add_argument("--conf", default="iso/airootfs/usr/share/limine/aedwen-limine.conf")
    ap.add_argument("--eagle", default=None,
                    help="eagle mask PNG (default: aedwen-eagle-mask.png next to --out)")
    args = ap.parse_args()

    if args.hue is not None:
        if not 0 <= args.hue <= 359:
            sys.exit("--hue must be 0..359")
        H_ = args.hue
    else:
        H_ = SEEDS[args.seed or DEFAULT_SEED]
    c = colours(H_)
    eagle = args.eagle or os.path.join(os.path.dirname(os.path.abspath(args.out)), "aedwen-eagle-mask.png")

    os.makedirs(os.path.dirname(os.path.abspath(args.out)), exist_ok=True)
    draw(args.out, c, eagle)
    print(f"Wrote {args.out} ({W}x{H}, hue={H_})")

    tmp = args.conf + ".tmp"
    with open(tmp, "w") as f:
        f.write(conf_text(c))
    os.replace(tmp, args.conf)
    print(f"Wrote {args.conf}")


if __name__ == "__main__":
    main()
