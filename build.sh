#!/usr/bin/env bash
# Build the AedwenOS ISO with archiso's mkarchiso.
#
#   ./build.sh                       # build into ./out, work in ~/.cache
#   WORK=/var/tmp/aedwen ./build.sh  # override the work dir
#
# Must run on an x86-64 Arch / Arch-based system (needs mkarchiso + pacman).
# Non-Arch hosts: build inside an Arch container/VM -- see README.
#   pacman -S archiso
set -euo pipefail

here="$(dirname "$(readlink -f "$0")")"
profile="$here/iso"
out="${OUT:-$here/out}"

# mkarchiso needs a POSIX filesystem for the work dir (creates symlinks, sets
# ownership + xattrs). This repo often lives on NTFS/exFAT, where that fails
# with "cannot create symbolic link ... Invalid argument" and silently yields
# a broken chroot (0-byte initramfs -> "VFS: unable to mount root fs" panic).
# Default work/ to a local ext4/btrfs path; override with WORK=.
work="${WORK:-/var/tmp/aedwen-work}"

fstype="$(findmnt -no FSTYPE --target "$(dirname "$work")" 2>/dev/null || true)"
case "$fstype" in
    ntfs|ntfs3|exfat|vfat|fat|msdos|fuseblk)
        echo "error: work dir '$work' is on '$fstype' -- mkarchiso needs ext4/btrfs/xfs." >&2
        echo "       run: WORK=\$HOME/aedwen-work ./build.sh   (on a POSIX filesystem)" >&2
        exit 1 ;;
esac

if [[ $EUID -ne 0 ]]; then
    exec sudo --preserve-env=SOURCE_DATE_EPOCH WORK="$work" OUT="$out" "$0" "$@"
fi

command -v mkarchiso >/dev/null || { echo "install 'archiso' first"; exit 1; }

rm -rf "$work"
mkdir -p "$work" "$out"

mkarchiso -v -w "$work" -o "$out" "$profile"

echo
echo "ISO written to: $out"
ls -lh "$out"/*.iso
