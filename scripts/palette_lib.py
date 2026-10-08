"""Shared OKLCH->sRGB palette math for AedwenOS theme generators.

Ported 1:1 from the `palette()` function embedded in the
"AedwenOS System Surfaces" design (claude.ai/design project
"AedwenOS desktop styling"). Keep this in sync with that source if the
design changes -- it is the single place every generator script imports
seed/colour logic from.
"""

import math

SEEDS = {"blue": 250, "violet": 295, "teal": 185, "green": 145, "amber": 70, "rose": 10}
SEED_HEX = {
    "blue": "#4d7fdc",
    "violet": "#8a64d6",
    "teal": "#1f9a93",
    "green": "#3f9a52",
    "amber": "#c4841c",
    "rose": "#d0507a",
}


def oklch_to_srgb_hex(L, C, H):
    C = min(C, 0.2)
    a = C * math.cos(math.radians(H))
    b = C * math.sin(math.radians(H))

    l_ = L + 0.3963377774 * a + 0.2158037573 * b
    m_ = L - 0.1055613458 * a - 0.0638541728 * b
    s_ = L - 0.0894841775 * a - 1.2914855480 * b
    l, m, s = l_**3, m_**3, s_**3

    r = 4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s
    g = -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s
    bl = -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s

    def to_srgb(c):
        c = max(0.0, min(1.0, c))
        c = 12.92 * c if c <= 0.0031308 else 1.055 * c ** (1 / 2.4) - 0.055
        return round(max(0.0, min(1.0, c)) * 255)

    return "#{:02x}{:02x}{:02x}".format(to_srgb(r), to_srgb(g), to_srgb(bl))


def o(l, c, h):
    return oklch_to_srgb_hex(l, c, h)


def srgb_hex_to_oklch(hex_color):
    """Inverse of oklch_to_srgb_hex: (L, C, H in degrees)."""
    hex_color = hex_color.lstrip("#")

    def lin(i):
        c = int(hex_color[i : i + 2], 16) / 255
        return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4

    r, g, b = lin(0), lin(2), lin(4)
    l = (0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b) ** (1 / 3)
    m = (0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b) ** (1 / 3)
    s_ = (0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b) ** (1 / 3)
    L = 0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s_
    A = 1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s_
    B = 0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s_
    return L, math.hypot(A, B), math.degrees(math.atan2(B, A)) % 360


def seed_hex_for(hex_color):
    """The seed colour (as in SEED_HEX) for any accent colour, e.g. KDE's
    AccentColor, which is the palette's light primary rather than the seed:
    a preset's own seed when the hue is within 10 degrees of it, otherwise
    a colour at the presets' typical seed lightness/chroma on that hue."""
    _, _, h = srgb_hex_to_oklch(hex_color)
    for name, sh in SEEDS.items():
        if min(abs(h - sh), 360 - abs(h - sh)) <= 10:
            return SEED_HEX[name]
    return oklch_to_srgb_hex(0.6, 0.15, h)


def palette(H, dark, expressive):
    k = 1.5 if expressive else 1.0
    T = H + 70
    if dark:
        return {
            "surface": o(0.155, 0.012 * k, H),
            "sc-low": o(0.18, 0.015 * k, H),
            "sc": o(0.205, 0.016 * k, H),
            "sc-high": o(0.235, 0.017 * k, H),
            "sc-highest": o(0.265, 0.018 * k, H),
            "on-s": o(0.92, 0.012, H),
            "on-sv": o(0.8, 0.025, H),
            "outline": o(0.62, 0.02, H),
            "outline-v": o(0.36, 0.02, H),
            "primary": o(0.82, 0.11 * k, H),
            "on-primary": o(0.28, 0.09, H),
            "pc": o(0.38, 0.1 * k, H),
            "on-pc": o(0.93, 0.05, H),
            "sec-c": o(0.33, 0.035 * k, H),
            "on-sec-c": o(0.9, 0.025, H),
            "ter-c": o(0.37, 0.08 * k, T),
            "on-ter-c": o(0.93, 0.05, T),
            "err-c": o(0.4, 0.13, 25),
            "on-err-c": o(0.92, 0.05, 25),
            "err": o(0.8, 0.13, 25),
        }
    return {
        "surface": o(0.985, 0.006, H),
        "sc-low": o(0.965, 0.01 * k, H),
        "sc": o(0.95, 0.012 * k, H),
        "sc-high": o(0.935, 0.014 * k, H),
        "sc-highest": o(0.915, 0.016 * k, H),
        "on-s": o(0.21, 0.015, H),
        "on-sv": o(0.42, 0.025, H),
        "outline": o(0.56, 0.02, H),
        "outline-v": o(0.84, 0.015, H),
        "primary": o(0.5, 0.14 * k, H),
        "on-primary": o(1, 0, H),
        "pc": o(0.9, 0.06 * k, H),
        "on-pc": o(0.3, 0.1, H),
        "sec-c": o(0.91, 0.03 * k, H),
        "on-sec-c": o(0.28, 0.03, H),
        "ter-c": o(0.91, 0.06 * k, T),
        "on-ter-c": o(0.3, 0.08, T),
        "err-c": o(0.92, 0.06, 25),
        "on-err-c": o(0.35, 0.13, 25),
        "err": o(0.5, 0.18, 25),
    }


def hex_to_rgb_csv(hex_color):
    hex_color = hex_color.lstrip("#")
    return ",".join(str(int(hex_color[i : i + 2], 16)) for i in (0, 2, 4))


DEFAULT_SEED = "violet"
DEFAULT_DARK = True
DEFAULT_EXPRESSIVE = True
