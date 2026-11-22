#!/usr/bin/env python3
"""Check that the committed theme files still match their generators.

Copies the working tree to a temp dir, re-runs the generators there, and
compares the results with your files (so it also works on uncommitted
changes). Also runs scripts/check-contrast.py. Exits 1 if any generated file
is out of date (re-run the generator and commit) or any palette pair is below
the WCAG limits.

  python3 -I scripts/check-theme.py
  python3 -I scripts/check-theme.py -v      # show every generator and its output

Generators that need tools this machine lacks (xcursorgen, Pillow, fontTools)
are skipped and listed; CI installs them so nothing is skipped there.
"""
import gzip
import importlib.util
import os
import shutil
import subprocess
import sys
import tempfile

ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
PY = [sys.executable, "-I"]
# (name, args, needs): `needs` is a python module or an executable that must exist
GENERATORS = [
    ("generate-colorscheme.py", [], None),
    ("generate-kdeglobals.py", [], None),
    ("generate-aurorae-theme.py", [], None),
    ("generate-gtk-theme.py", [], None),
    ("generate-plasma-theme.py", [], None),
    ("generate-plasma-theme.py", ["--contrast", "high"], None),
    ("generate-app-themes.py", [], None),
    ("generate-sounds.py", [], None),
    ("generate-m3-shapes.py", [], None),
    ("generate-plymouth-assets.py", [], "PIL"),
    ("generate-limine-wallpaper.py", [], "PIL"),
    ("generate-desktop-wallpaper.py", [], "cairo"),
    ("generate-icons.py", ["--all-static"], None),
    ("generate-cursors.py", ["--all-static"], "xcursorgen"),
]
IGNORE = {".git", "work", "out", "localrepo", "__pycache__"}


def have(need):
    if need is None:
        return True
    if need == "xcursorgen":
        return shutil.which(need) is not None
    return importlib.util.find_spec(need) is not None


def content(path):
    """File content for comparison: .svgz and .png are compared decoded (their
    bytes carry timestamps / encoder details)."""
    if path.endswith(".svgz"):
        with gzip.open(path, "rb") as f:
            return f.read()
    if path.endswith(".png") and importlib.util.find_spec("PIL"):
        from PIL import Image
        im = Image.open(path).convert("RGBA")
        return im.tobytes() + repr(im.size).encode()
    with open(path, "rb") as f:
        return f.read()


def main():
    verbose = "-v" in sys.argv
    fails = 0
    skipped = []
    tmp = tempfile.mkdtemp(prefix="aedwen-theme-")
    try:
        work = os.path.join(tmp, "tree")
        shutil.copytree(ROOT, work, symlinks=True, ignore=lambda d, names: [n for n in names if n in IGNORE])
        for name, args, need in GENERATORS:
            label = " ".join([name] + args)
            if not have(need):
                skipped.append(f"{label} (needs {need})")
                continue
            r = subprocess.run(PY + [os.path.join("scripts", name)] + args, cwd=work,
                               capture_output=True, text=True)
            if r.returncode != 0:
                print(f"FAIL {label} exited {r.returncode}: {r.stderr.strip().splitlines()[-1:]}")
                fails += 1
            elif verbose:
                print(f"ran  {label}")
        stale = []
        for dirpath, dirs, files in os.walk(os.path.join(work, "iso")):
            dirs[:] = [d for d in dirs if d not in IGNORE]
            for fn in files:
                new = os.path.join(dirpath, fn)
                rel = os.path.relpath(new, work)
                old = os.path.join(ROOT, rel)
                # Ogg files carry a random stream serial: not comparable byte for byte
                if os.path.islink(new) or fn.endswith(".oga"):
                    continue
                if not os.path.exists(old):
                    stale.append(f"{rel} (generated, not in the repo)")
                elif content(new) != content(old):
                    stale.append(f"{rel} (differs from its generator)")
        for s in sorted(stale):
            print("STALE", s)
        fails += len(stale)
    finally:
        shutil.rmtree(tmp, ignore_errors=True)

    r = subprocess.run(PY + [os.path.join(ROOT, "scripts", "check-contrast.py")], capture_output=True, text=True)
    print(r.stdout.strip().splitlines()[-1] if r.stdout.strip() else "check-contrast: no output")
    if r.returncode:
        print(r.stdout)
        fails += 1
    for s in skipped:
        print("skipped", s)
    print("theme check:", "FAILED" if fails else "ok")
    return 1 if fails else 0


if __name__ == "__main__":
    sys.exit(main())
