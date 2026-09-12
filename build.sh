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

# --- preflight: fail fast on the things that otherwise surface as a cryptic
# "target not found" or keyring error 20 minutes into the build. ---
localrepo="$profile/localrepo"
for pkg in $(grep -oE '^(calamares|ckbcomp|zed-bin)$' "$profile/packages.x86_64"); do
    if ! compgen -G "$localrepo/${pkg}-[0-9]*.pkg.tar.zst" >/dev/null; then
        echo "error: $pkg is not staged in iso/localrepo/ -- run ./scripts/build-localrepo.sh (as your normal user) first" >&2
        exit 1
    fi
done
[[ -f "$localrepo/aedwen-local.db" ]] || { echo "error: iso/localrepo/aedwen-local.db missing -- run ./scripts/build-localrepo.sh" >&2; exit 1; }
[[ -f /etc/pacman.d/chaotic-mirrorlist ]] || { echo "error: chaotic-mirrorlist not installed on the build host -- see iso/pacman.conf" >&2; exit 1; }
pacman-key --list-keys 3056513887B78AEB &>/dev/null || { echo "error: chaotic-aur key not in the build host keyring -- see iso/pacman.conf" >&2; exit 1; }

# iso/pacman.conf is only used by mkarchiso on the build host; render the
# absolute local-repo path into a temp copy rather than hardcoding a checkout
# location in the repo.
pacconf="$(mktemp --suffix=.pacman.conf)"
trap 'rm -f "$pacconf"' EXIT
sed "s|@LOCALREPO@|$localrepo|" "$profile/pacman.conf" > "$pacconf"

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

mkarchiso -v -w "$work" -o "$out" -C "$pacconf" "$profile"

echo
echo "ISO written to: $out"
ls -lh "$out"/*.iso
