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
    "blue": "#4d7fdc", "violet": "#8a64d6", "teal": "#1f9a93",
    "green": "#3f9a52", "amber": "#c4841c", "rose": "#d0507a",
}


def oklch_to_srgb_hex(L, C, H):
    C = min(C, 0.2)
    a = C * math.cos(math.radians(H))
    b = C * math.sin(math.radians(H))

    l_ = L + 0.3963377774 * a + 0.2158037573 * b
    m_ = L - 0.1055613458 * a - 0.0638541728 * b
    s_ = L - 0.0894841775 * a - 1.2914855480 * b
    l, m, s = l_ ** 3, m_ ** 3, s_ ** 3

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


def palette(H, dark, expressive):
    k = 1.5 if expressive else 1.0
    T = H + 70
    if dark:
        return {
            "surface": o(0.155, 0.012 * k, H), "sc-low": o(0.18, 0.015 * k, H), "sc": o(0.205, 0.016 * k, H),
            "sc-high": o(0.235, 0.017 * k, H), "sc-highest": o(0.265, 0.018 * k, H),
            "on-s": o(0.92, 0.012, H), "on-sv": o(0.8, 0.025, H),
            "outline": o(0.62, 0.02, H), "outline-v": o(0.36, 0.02, H),
            "primary": o(0.82, 0.11 * k, H), "on-primary": o(0.28, 0.09, H),
            "pc": o(0.38, 0.1 * k, H), "on-pc": o(0.93, 0.05, H),
            "sec-c": o(0.33, 0.035 * k, H), "on-sec-c": o(0.9, 0.025, H),
            "ter-c": o(0.37, 0.08 * k, T), "on-ter-c": o(0.93, 0.05, T),
            "err-c": o(0.4, 0.13, 25), "on-err-c": o(0.92, 0.05, 25), "err": o(0.8, 0.13, 25),
        }
    return {
        "surface": o(0.985, 0.006, H), "sc-low": o(0.965, 0.01 * k, H), "sc": o(0.95, 0.012 * k, H),
        "sc-high": o(0.935, 0.014 * k, H), "sc-highest": o(0.915, 0.016 * k, H),
        "on-s": o(0.21, 0.015, H), "on-sv": o(0.42, 0.025, H),
        "outline": o(0.56, 0.02, H), "outline-v": o(0.84, 0.015, H),
        "primary": o(0.5, 0.14 * k, H), "on-primary": o(1, 0, H),
        "pc": o(0.9, 0.06 * k, H), "on-pc": o(0.3, 0.1, H),
        "sec-c": o(0.91, 0.03 * k, H), "on-sec-c": o(0.28, 0.03, H),
        "ter-c": o(0.91, 0.06 * k, T), "on-ter-c": o(0.3, 0.08, T),
        "err-c": o(0.92, 0.06, 25), "on-err-c": o(0.35, 0.13, 25), "err": o(0.5, 0.18, 25),
    }


def hex_to_rgb_csv(hex_color):
    hex_color = hex_color.lstrip("#")
    return ",".join(str(int(hex_color[i:i + 2], 16)) for i in (0, 2, 4))


DEFAULT_SEED = "violet"
DEFAULT_DARK = True
DEFAULT_EXPRESSIVE = True
