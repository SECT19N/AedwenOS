#!/usr/bin/env python3
"""Check the WCAG contrast of every palette: seeds x dark/light x
expressive/baseline x standard/medium/high.

Text pairs must reach 4.5:1 (standard), 7:1 (medium and high); non-text
pairs (outline, primary against the surface) 3:1. Exits 1 on any failure.

  python3 -I scripts/check-contrast.py          # failures only
  python3 -I scripts/check-contrast.py -v       # every ratio
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from palette_lib import CONTRASTS, SEEDS, contrast_ratio, palette_contrast  # noqa: E402

# (foreground role, background role, kind)
PAIRS = [
    ("on-s", "surface", "text"), ("on-s", "sc-highest", "text"),
    ("on-sv", "surface", "text"), ("on-sv", "sc-highest", "text"),
    ("on-primary", "primary", "text"), ("on-pc", "pc", "text"),
    ("on-sec-c", "sec-c", "text"), ("on-err-c", "err-c", "text"),
    ("primary", "surface", "ui"), ("outline", "surface", "ui"),
    ("outline", "sc-highest", "ui"),
]
MIN = {"standard": {"text": 4.5, "ui": 3.0},
       "medium": {"text": 4.5, "ui": 3.0},
       "high": {"text": 7.0, "ui": 4.5}}


def main():
    verbose = "-v" in sys.argv
    fails = checked = 0
    for seed, hue in SEEDS.items():
        for dark in (True, False):
            for expressive in (True, False):
                for level in CONTRASTS:
                    p = palette_contrast(hue, dark, expressive, level)
                    for fg, bg, kind in PAIRS:
                        if fg not in p or bg not in p:
                            continue
                        ratio = contrast_ratio(p[fg], p[bg])
                        need = MIN[level][kind]
                        checked += 1
                        bad = ratio < need
                        fails += bad
                        if bad or verbose:
                            print(f"{'FAIL' if bad else 'ok  '} {seed:6} {'dark ' if dark else 'light'} "
                                  f"{'expr' if expressive else 'base'} {level:8} {fg} on {bg}: "
                                  f"{ratio:5.2f} (need {need})")
    print(f"{checked} pairs checked, {fails} failing")
    return 1 if fails else 0


if __name__ == "__main__":
    sys.exit(main())
