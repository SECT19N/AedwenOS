#!/usr/bin/env bash
# Build the AedwenOS ISO with archiso's mkarchiso.
#
#   ./build.sh            # build into ./out
#
# Must run on an x86-64 Arch / Arch-based system (needs mkarchiso + pacman).
# Non-Arch hosts: build inside an Arch container/VM -- see README.
#   pacman -S archiso
set -euo pipefail

here="$(dirname "$(readlink -f "$0")")"
profile="$here/iso"
work="$here/work"
out="$here/out"

if [[ $EUID -ne 0 ]]; then
    exec sudo --preserve-env=SOURCE_DATE_EPOCH "$0" "$@"
fi

command -v mkarchiso >/dev/null || { echo "install 'archiso' first"; exit 1; }

rm -rf "$work"
mkdir -p "$out"

mkarchiso -v -w "$work" -o "$out" "$profile"

echo
echo "ISO written to: $out"
ls -lh "$out"/*.iso
