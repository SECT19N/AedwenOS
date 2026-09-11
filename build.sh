#!/usr/bin/env bash
# Build the AedwenOS ISO with archiso's mkarchiso.
#
#   ./build.sh                       # build into ./out, work in ~/.cache
#   ./build.sh --fast                # lower squashfs compression for quick dev/test builds
#   WORK=/var/tmp/aedwen ./build.sh  # override the work dir
#
# Must run on an x86-64 Arch / Arch-based system (needs mkarchiso + pacman).
# Non-Arch hosts: build inside an Arch container/VM -- see README.
#   pacman -S archiso
set -euo pipefail

here="$(dirname "$(readlink -f "$0")")"
profile="$here/iso"
out="${OUT:-$here/out}"

# --fast: skip the slow max-ratio squashfs compression (zstd -19) in favor of
# a much quicker level, for iterating in a VM. Read from iso/profiledef.sh.
export FAST=0
for arg in "$@"; do
    case "$arg" in
        --fast) FAST=1 ;;
        *) echo "error: unknown argument '$arg'" >&2; exit 1 ;;
    esac
done

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
    exec sudo --preserve-env=SOURCE_DATE_EPOCH,FAST WORK="$work" OUT="$out" "$0" "$@"
fi

command -v mkarchiso >/dev/null || { echo "install 'archiso' first"; exit 1; }

# Tie the ISO's version string (and thus its output filename -- see
# iso/profiledef.sh) to the exact source it was built from, so same-day
# rebuilds don't overwrite each other and the artifact is traceable back to
# a commit. `-c safe.directory` sidesteps git's ownership check, since this
# runs as root against a repo owned by the invoking user.
export GIT_HASH
GIT_HASH="$(git -C "$here" -c safe.directory="$here" rev-parse --short HEAD 2>/dev/null || echo unknown)"
export GIT_DIRTY=""
[[ -n "$(git -C "$here" -c safe.directory="$here" status --porcelain 2>/dev/null)" ]] && GIT_DIRTY="-dirty"

[[ "$FAST" == 1 ]] && echo "--fast: using low squashfs compression for a quicker build"

rm -rf "$work"
mkdir -p "$work" "$out"

mkarchiso -v -w "$work" -o "$out" "$profile"

echo
echo "ISO written to: $out"
ls -lh "$out"/*.iso
