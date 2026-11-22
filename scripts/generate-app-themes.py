#!/usr/bin/env python3
"""
Generate the AedwenOS themes for apps that carry their own colours: the
Konsole colour scheme + profile and the Kate/KTextEditor editor themes
(KSyntaxHighlighting JSON). Okular, Gwenview and the rest of Kate follow the
Plasma colour scheme (kdeglobals) already.

Konsole is the design's terminal (System Desktop design, window "Terminal"):
always dark, surface oklch(0.15 0.012 H / .96), text #dde0ea, dim #8a90a6,
the accent for the prompt (here: the cursor), IBM Plex Mono.

Usage:
    scripts/generate-app-themes.py --all-static       # what the ISO ships (violet)
    scripts/generate-app-themes.py [--seed violet | --accent '#rrggbb']
                                   [--variant expressive|baseline]
                                   [--konsole DIR] [--kate DIR]

The ISO ships the violet defaults; aedwen-apps (/usr/local/bin) calls this on
the user's machine with the current accent into ~/.local/share.
"""

import argparse
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from palette_lib import SEED_HEX, o, palette, palette_contrast, srgb_hex_to_oklch  # noqa: E402

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "iso", "airootfs", "usr", "share")
KONSOLE_DIR = os.path.normpath(os.path.join(ROOT, "konsole"))
KATE_DIR = os.path.normpath(os.path.join(ROOT, "org.kde.syntax-highlighting", "themes"))

FG, FG_DIM, FG_BRIGHT = "#dde0ea", "#8a90a6", "#ffffff"
# ANSI hues (OKLCH degrees): red, green, yellow, blue, magenta, cyan
ANSI_HUES = (25, 145, 95, 255, 330, 200)
ANSI_NAMES = ("Red", "Green", "Yellow", "Blue", "Magenta", "Cyan")


def rgb(hexc):
    h = hexc.lstrip("#")
    return ",".join(str(int(h[i:i + 2], 16)) for i in (0, 2, 4))


def lum(hexc):
    h = hexc.lstrip("#")
    c = [int(h[i:i + 2], 16) / 255 for i in (0, 2, 4)]
    c = [v / 12.92 if v <= 0.03928 else ((v + 0.055) / 1.055) ** 2.4 for v in c]
    return 0.2126 * c[0] + 0.7152 * c[1] + 0.0722 * c[2]


def contrast(a, b):
    la, lb = sorted((lum(a), lum(b)), reverse=True)
    return (la + 0.05) / (lb + 0.05)


def konsole_scheme(hue, high=False):
    # high contrast: pure black background, white text
    fg, fg_dim = ("#ffffff", "#e0e0e0") if high else (FG, FG_DIM)
    bg = "#000000" if high else o(0.15, 0.012, hue)
    bg_faint = "#000000" if high else o(0.13, 0.012, hue)
    bg_int = "#000000" if high else o(0.17, 0.014, hue)
    colors = {}
    # slots: 0 black, 1..6 colours, 7 white; normal and Intense (bright)
    colors[0] = (o(0.28, 0.015, hue), o(0.45, 0.02, hue))
    for i, h in enumerate(ANSI_HUES, 1):
        colors[i] = (o(0.80, 0.13, h), o(0.88, 0.12, h)) if high else (o(0.72, 0.13, h), o(0.82, 0.12, h))
    colors[7] = ("#ffffff", "#ffffff") if high else ("#c8ccd8", FG_BRIGHT)
    out = []

    def sect(name, color):
        out.append(f"[{name}]\nColor={rgb(color)}\n")

    sect("Background", bg)
    sect("BackgroundFaint", bg_faint)
    sect("BackgroundIntense", bg_int)
    for i in range(8):
        sect(f"Color{i}", colors[i][0])
        sect(f"Color{i}Faint", o(0.22, 0.015, hue) if i == 0 else colors[i][0])
        sect(f"Color{i}Intense", colors[i][1])
    sect("Foreground", fg)
    sect("ForegroundFaint", fg_dim)
    sect("ForegroundIntense", FG_BRIGHT)
    out.append("[General]\nAnchor=0.5,0.5\nBlur=false\nColorRandomization=false\n"
               "Description=AedwenOS\nFillStyle=Tile\nOpacity=0.96\nWallpaper=\n"
               "WallpaperFlipType=NoFlip\nWallpaperOpacity=1\n")
    problems = [f"Color{i}" for i in range(8)
                if contrast(colors[i][0], bg) < (7 if high else 3) and i != 0]
    return "\n".join(out), bg, problems


def konsole_profile(hue, expressive):
    accent = palette(hue, True, expressive)["primary"]
    return f"""[Appearance]
ColorScheme=AedwenOS
Font=IBM Plex Mono,11,-1,5,400,0,0,0,0,0,0,0,0,0,0,1

[Cursor Options]
CursorShape=1
CustomCursorColor={rgb(accent)}
UseCustomCursorColor=true

[General]
Name=AedwenOS
Parent=FALLBACK/
TerminalMargin=12
TerminalCenter=false

[Scrolling]
ScrollBarPosition=2

[Interaction Options]
TrimTrailingSpacesInSelectedText=true
"""


def kate_theme(name, hue, dark, expressive, contrast="standard"):
    p = palette_contrast(hue, dark, expressive, contrast)
    hi = contrast == "high"
    k = 1.5 if expressive else 1.0
    # lightness of the syntax colours / marks: stronger at high contrast
    syn_l = (0.88 if hi else 0.8) if dark else (0.33 if hi else 0.42)
    mark_l = (0.85 if hi else 0.75) if dark else (0.4 if hi else 0.5)
    sat = lambda h: o(syn_l, 0.12 if dark else 0.14, h)
    fg = p["on-s"]
    plain = lambda c, **kw: {"text-color": c, "selected-text-color": c, **kw}

    ts = {
        "Normal": plain(fg),
        "Keyword": plain(sat(hue), bold=True),
        "ControlFlow": plain(sat(hue), bold=True),
        "Operator": plain(p["on-sv"]),
        "Function": plain(sat(hue + 60)),
        "Import": plain(sat(hue + 300)),
        "Preprocessor": plain(sat(hue + 300)),
        "BuiltIn": plain(sat(hue + 60), bold=True),
        "DataType": plain(sat(hue + 120)),
        "Variable": plain(fg),
        "Attribute": plain(sat(hue + 120)),
        "Extension": plain(sat(hue + 60), bold=True),
        "Constant": plain(sat(hue + 240)),
        "String": plain(sat(hue + 150)),
        "VerbatimString": plain(sat(hue + 150)),
        "SpecialString": plain(sat(hue + 180)),
        "Char": plain(sat(hue + 150)),
        "SpecialChar": plain(sat(hue + 180)),
        "DecVal": plain(sat(hue + 210)),
        "BaseN": plain(sat(hue + 210)),
        "Float": plain(sat(hue + 210)),
        "Comment": plain(p["outline"], italic=True),
        "CommentVar": plain(p["outline"], italic=True),
        "Documentation": plain(p["on-sv"], italic=True),
        "Annotation": plain(sat(hue + 270)),
        "Information": plain(sat(hue + 100)),
        "Warning": plain(o(mark_l, 0.14, 70)),
        "Alert": plain(p["err"], bold=True),
        "Error": plain(p["err"], underline=True),
        "Others": plain(fg),
        "RegionMarker": plain(p["on-pc"], **{"background-color": p["pc"]}),
    }
    alpha = lambda c, a: "#" + a + c.lstrip("#")
    ec = {
        "BackgroundColor": p["surface"],
        "BracketMatching": alpha(p["primary"], "40"),
        "CodeFolding": alpha(p["primary"], "30"),
        "CurrentLine": p["sc-low"],
        "CurrentLineNumber": p["on-s"],
        "IconBorder": p["surface"],
        "IndentationLine": p["outline-v"],
        "LineNumbers": p["outline"],
        "MarkBookmark": p["primary"],
        "MarkBreakpointActive": p["err"],
        "MarkBreakpointDisabled": p["outline"],
        "MarkBreakpointReached": o(mark_l, 0.14, 145),
        "MarkError": p["err"],
        "MarkExecution": p["on-sv"],
        "MarkWarning": o(mark_l, 0.14, 70),
        "ModifiedLines": o(mark_l, 0.14, 70),
        "ReplaceHighlight": alpha(o(mark_l, 0.14, 145), "66"),
        "SavedLines": o(mark_l, 0.14, 145),
        "SearchHighlight": alpha(p["primary"], "66"),
        "Separator": p["outline-v"],
        "SpellChecking": p["err"],
        "TabMarker": p["outline-v"],
        "TemplateBackground": p["sc-high"],
        "TemplateFocusedPlaceholder": p["pc"],
        "TemplatePlaceholder": p["sec-c"],
        "TemplateReadOnlyPlaceholder": p["err-c"],
        "TextSelection": p["pc"],
        "WordWrapMarker": p["outline-v"],
    }
    return {"metadata": {"name": name, "revision": 1}, "editor-colors": ec, "text-styles": ts}, ts, p


def write(path, text):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w") as fh:
        fh.write(text)


def build(hue, expressive, konsole_dir, kate_dir, contrast="standard"):
    contrast_ratio = globals()["contrast"]  # the module-level WCAG helper (shadowed by the parameter)
    high = contrast == "high"
    scheme, bg, problems = konsole_scheme(hue, high)
    write(os.path.join(konsole_dir, "AedwenOS.colorscheme"), scheme)
    write(os.path.join(konsole_dir, "Aedwen.profile"), konsole_profile(hue, expressive))
    bad = [f"konsole {n}" for n in problems]
    for dark, nm in ((True, "AedwenOS Dark"), (False, "AedwenOS Light")):
        theme, ts, p = kate_theme(nm, hue, dark, expressive, contrast)
        write(os.path.join(kate_dir, nm + ".theme"), json.dumps(theme, indent=4) + "\n")
        bg_ = p["surface"]
        bad += [f"{nm} {s}" for s, v in ts.items()
                if s not in ("Comment", "CommentVar", "RegionMarker", "Documentation")
                and contrast_ratio(v["text-color"], bg_) < (7 if high else 4.5)]
    return bad


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--all-static", action="store_true")
    ap.add_argument("--seed", default="violet", choices=SEED_HEX.keys())
    ap.add_argument("--accent")
    ap.add_argument("--variant", default="expressive", choices=["expressive", "baseline"])
    ap.add_argument("--contrast", default="standard", choices=["standard", "high"])
    ap.add_argument("--konsole", default=KONSOLE_DIR)
    ap.add_argument("--kate", default=KATE_DIR)
    args = ap.parse_args()
    hexc = args.accent or SEED_HEX[args.seed]
    hue = srgb_hex_to_oklch(hexc)[2]
    bad = build(hue, args.variant == "expressive", args.konsole, args.kate, args.contrast)
    print(f"Wrote Konsole + Kate themes for {hexc} to {args.konsole} / {args.kate}")
    if bad:
        print("low contrast: " + ", ".join(bad), file=sys.stderr)


if __name__ == "__main__":
    main()
