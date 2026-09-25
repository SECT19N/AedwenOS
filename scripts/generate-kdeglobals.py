#!/usr/bin/env python3
"""
Generate the real, per-user AedwenOS kdeglobals: the actual [Colors:*] /
[WM] / [ColorEffects:*] values (not just a `ColorScheme=` name pointer).

KColorScheme reads its palette straight out of kdeglobals's own [Colors:*]
groups -- it does NOT automatically resolve `ColorScheme=<name>` to
/usr/share/color-schemes/<name>.colors at runtime. That file only exists so
the "Colors" KCM can list it and copy its sections into kdeglobals when a
user picks it from the UI (this is what `plasma-apply-colorscheme` does).
For a default that actually renders on first login, the values need to be
inlined here directly, in both:
  - iso/airootfs/etc/skel/.config/kdeglobals (real per-user file, wins over
    everything, used by every account `useradd -m` creates: the live user
    and every aedwen-install target)
  - iso/airootfs/etc/xdg/kdeglobals (system fallback, for root / any account
    that bypasses skel)

Usage:
    scripts/generate-kdeglobals.py [--seed violet] [--theme dark] [--variant expressive]

Re-run after editing scripts/palette_lib.py or scripts/generate-colorscheme.py's
render_colors() to keep kdeglobals in sync with the .colors files.
"""

import argparse
import configparser
import io
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from palette_lib import SEEDS  # noqa: E402


def _load_render_colors():
    # generate-colorscheme.py has a hyphen, so import it by path instead of name.
    import importlib.util

    spec = importlib.util.spec_from_file_location(
        "generate_colorscheme",
        os.path.join(
            os.path.dirname(os.path.abspath(__file__)), "generate-colorscheme.py"
        ),
    )
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod.render_colors, mod.hexname


def build_kdeglobals(seed, dark, expressive):
    render_colors, hexname = _load_render_colors()
    base_text = render_colors(seed, dark, expressive)

    cp = configparser.ConfigParser()
    cp.optionxform = str  # preserve KDE's CamelCase keys
    cp.read_string(base_text)

    # Extra keys layered on top of the generated colour/WM/effects sections.
    cp.set("General", "widgetStyle", "Breeze")
    cp.set("General", "font", "Roboto,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1")
    cp.set("General", "menuFont", "Roboto,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1")
    cp.set("General", "toolBarFont", "Roboto,9,-1,5,400,0,0,0,0,0,0,0,0,0,0,1")
    cp.set("General", "fixed", "Roboto Mono,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1")

    cp.set("KDE", "LookAndFeelPackage", "org.kde.aedwen.desktop")
    cp.set("KDE", "SingleClick", "false")

    cp.add_section("Icons")
    cp.set("Icons", "Theme", "breeze-dark")

    out = io.StringIO()
    cp.write(out, space_around_delimiters=False)
    return out.getvalue()


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--seed", default="violet", choices=SEEDS.keys())
    ap.add_argument("--theme", default="dark", choices=["dark", "light"])
    ap.add_argument(
        "--variant", default="expressive", choices=["baseline", "expressive"]
    )
    ap.add_argument("--skel", default="iso/airootfs/etc/skel/.config/kdeglobals")
    ap.add_argument("--xdg", default="iso/airootfs/etc/xdg/kdeglobals")
    args = ap.parse_args()

    content = build_kdeglobals(
        args.seed, args.theme == "dark", args.variant == "expressive"
    )

    for path in (args.skel, args.xdg):
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, "w") as f:
            f.write(content)
        print(f"Wrote {path}")


if __name__ == "__main__":
    main()
