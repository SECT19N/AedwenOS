#!/usr/bin/env python3
"""
Generate AedwenOS KDE Plasma colour schemes from the same OKLCH palette
function used by the "AedwenOS System Surfaces" design (seed hue + light/dark
+ baseline/expressive chroma multiplier).

Usage:
    scripts/generate-colorscheme.py [--out DIR]

Writes one .colors file per seed x theme combination into
iso/airootfs/usr/share/color-schemes/, plus prints the default
(violet, dark, expressive) hex values.
"""

import argparse
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from palette_lib import SEEDS, hex_to_rgb_csv, palette  # noqa: E402


def hexname(seed, dark, expressive):
    return f"AedwenOS{seed.capitalize()}{'Dark' if dark else 'Light'}{'Expressive' if expressive else ''}"


def render_colors(seed, dark, expressive):
    H = SEEDS[seed]
    p = palette(H, dark, expressive)
    name = hexname(seed, dark, expressive)
    label = f"AedwenOS · {seed.capitalize()} ({'Dark' if dark else 'Light'})"

    return f"""[ColorEffects:Disabled]
Color=56,56,56
ColorAmount=0
ColorEffect=0
ContrastAmount=0.65
ContrastEffect=1
IntensityAmount=0.1
IntensityEffect=2

[ColorEffects:Inactive]
ChangeSelectionColor=true
Color=112,111,110
ColorAmount=0.025
ColorEffect=2
ContrastAmount=0.1
ContrastEffect=2
Enable=false
IntensityAmount=0
IntensityEffect=0

[Colors:Button]
BackgroundAlternate={p["sc-highest"]}
BackgroundNormal={p["sc-high"]}
DecorationFocus={p["primary"]}
DecorationHover={p["primary"]}
ForegroundActive={p["primary"]}
ForegroundInactive={p["on-sv"]}
ForegroundLink={p["primary"]}
ForegroundNegative={p["err"]}
ForegroundNeutral={p["ter-c"]}
ForegroundNormal={p["on-s"]}
ForegroundPositive={p["pc"]}
ForegroundVisited={p["sec-c"]}

[Colors:Complementary]
BackgroundAlternate={p["sc"]}
BackgroundNormal={p["sc-low"]}
DecorationFocus={p["primary"]}
DecorationHover={p["primary"]}
ForegroundActive={p["primary"]}
ForegroundInactive={p["on-sv"]}
ForegroundLink={p["primary"]}
ForegroundNegative={p["err"]}
ForegroundNeutral={p["ter-c"]}
ForegroundNormal={p["on-s"]}
ForegroundPositive={p["pc"]}
ForegroundVisited={p["sec-c"]}

[Colors:Header]
BackgroundAlternate={p["sc-high"]}
BackgroundNormal={p["sc"]}
DecorationFocus={p["primary"]}
DecorationHover={p["primary"]}
ForegroundActive={p["primary"]}
ForegroundInactive={p["on-sv"]}
ForegroundLink={p["primary"]}
ForegroundNegative={p["err"]}
ForegroundNeutral={p["ter-c"]}
ForegroundNormal={p["on-s"]}
ForegroundPositive={p["pc"]}
ForegroundVisited={p["sec-c"]}

[Colors:Selection]
BackgroundAlternate={p["pc"]}
BackgroundNormal={p["primary"]}
DecorationFocus={p["primary"]}
DecorationHover={p["primary"]}
ForegroundActive={p["on-primary"]}
ForegroundInactive={p["on-primary"]}
ForegroundLink={p["on-primary"]}
ForegroundNegative={p["err"]}
ForegroundNeutral={p["ter-c"]}
ForegroundNormal={p["on-primary"]}
ForegroundPositive={p["pc"]}
ForegroundVisited={p["sec-c"]}

[Colors:Tooltip]
BackgroundAlternate={p["sc-high"]}
BackgroundNormal={p["on-s"]}
DecorationFocus={p["primary"]}
DecorationHover={p["primary"]}
ForegroundActive={p["primary"]}
ForegroundInactive={p["on-sv"]}
ForegroundLink={p["primary"]}
ForegroundNegative={p["err"]}
ForegroundNeutral={p["ter-c"]}
ForegroundNormal={p["surface"]}
ForegroundPositive={p["pc"]}
ForegroundVisited={p["sec-c"]}

[Colors:View]
BackgroundAlternate={p["sc-low"]}
BackgroundNormal={p["surface"]}
DecorationFocus={p["primary"]}
DecorationHover={p["primary"]}
ForegroundActive={p["primary"]}
ForegroundInactive={p["on-sv"]}
ForegroundLink={p["primary"]}
ForegroundNegative={p["err"]}
ForegroundNeutral={p["ter-c"]}
ForegroundNormal={p["on-s"]}
ForegroundPositive={p["pc"]}
ForegroundVisited={p["sec-c"]}

[Colors:Window]
BackgroundAlternate={p["sc"]}
BackgroundNormal={p["surface"]}
DecorationFocus={p["primary"]}
DecorationHover={p["primary"]}
ForegroundActive={p["primary"]}
ForegroundInactive={p["on-sv"]}
ForegroundLink={p["primary"]}
ForegroundNegative={p["err"]}
ForegroundNeutral={p["ter-c"]}
ForegroundNormal={p["on-s"]}
ForegroundPositive={p["pc"]}
ForegroundVisited={p["sec-c"]}

[General]
AccentColor={hex_to_rgb_csv(p["primary"])}
ColorScheme={name}
Name={label}
shadeSortColumn=true

[KDE]
contrast=4

[WM]
activeBackground={p["sc"]}
activeBlend={p["on-s"]}
activeForeground={p["on-s"]}
inactiveBackground={p["surface"]}
inactiveBlend={p["on-sv"]}
inactiveForeground={p["on-sv"]}
"""


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default="iso/airootfs/usr/share/color-schemes")
    ap.add_argument(
        "--seed", default=None, help="Generate only this seed (default: all)"
    )
    args = ap.parse_args()

    os.makedirs(args.out, exist_ok=True)
    seeds = [args.seed] if args.seed else SEEDS.keys()
    written = []
    for seed in seeds:
        for dark in (True, False):
            for expressive in (True, False):
                name = hexname(seed, dark, expressive)
                path = os.path.join(args.out, f"{name}.colors")
                with open(path, "w") as f:
                    f.write(render_colors(seed, dark, expressive))
                written.append(path)

    print(f"Wrote {len(written)} colour schemes to {args.out}")
    print()
    print("Default (violet, dark, expressive) tokens:")
    for k, v in palette(SEEDS["violet"], True, True).items():
        print(f"  {k:12s} {v}")


if __name__ == "__main__":
    main()
