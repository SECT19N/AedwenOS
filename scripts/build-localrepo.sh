#!/usr/bin/env bash
# Build the packages that Arch dropped from its official repos and stage them in
# iso/localrepo/ so mkarchiso can pull them (see the [aedwen-local] repo in
# iso/pacman.conf).
#
#   ./scripts/build-localrepo.sh                             # build missing / outdated pkgs
#   ./scripts/build-localrepo.sh --force                     # rebuild everything
#   ./scripts/build-localrepo.sh --builddir /path/dir        # clone+build under a custom dir
#   ./scripts/build-localrepo.sh --clean                     # sweep leftover default-dir temp dirs
#   ./scripts/build-localrepo.sh --clean --builddir /path/dir  # wipe that custom dir instead
#
# --builddir must point at a real filesystem with exec+space (zed-bin alone
# needs a few GB to build); it is NOT wiped afterwards, so re-runs reuse
# whatever git clones / build artifacts are already there.
#
# Without --builddir, a fresh "$TMPDIR/aedwen-localrepo.XXXXXXXX" dir is used
# and removed on exit -- normally nothing to clean up. But if a run gets
# killed (crash, kill -9, power loss) the trap never fires and the dir is
# left behind; `--clean` (no --builddir) finds and removes any such leftovers
# under $TMPDIR by that name pattern. `--clean --builddir /path/dir` instead
# just deletes that one dir (equivalent to `rm -rf /path/dir`).
#
# Runs makepkg as your normal user (do NOT run with sudo); makepkg will call
# sudo itself to install build deps. Needs: base-devel, git.
set -euo pipefail

if [[ $EUID -eq 0 ]]; then
    echo "run this as your normal user, not root / sudo" >&2
    exit 1
fi

here="$(dirname "$(dirname "$(readlink -f "$0")")")"
repo="$here/iso/localrepo"
dbname="aedwen-local"
force=0
clean=0
builddir=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --force) force=1; shift ;;
        --clean) clean=1; shift ;;
        --builddir)
            [[ $# -ge 2 ]] || { echo "--builddir needs a path" >&2; exit 1; }
            builddir="$2"; shift 2 ;;
        --builddir=*) builddir="${1#--builddir=}"; shift ;;
        *) echo "unknown arg: $1" >&2; exit 1 ;;
    esac
done

tmpbase="${TMPDIR:-/tmp}"
tmpprefix="aedwen-localrepo"

if [[ $clean -eq 1 ]]; then
    if [[ -n "$builddir" ]]; then
        echo ">> removing $builddir"
        rm -rf -- "$builddir"
    else
        found=0
        for d in "$tmpbase/$tmpprefix".*; do
            [[ -e "$d" ]] || continue
            found=1
            echo ">> removing leftover $d"
            rm -rf -- "$d"
        done
        [[ $found -eq 1 ]] || echo ">> nothing to clean under $tmpbase/$tmpprefix.*"
    fi
    exit 0
fi

# AUR packages to build, in dependency order.
pkgs=(ckbcomp calamares zed-bin linux-wifi-hotspot)

mkdir -p "$repo"
if [[ -n "$builddir" ]]; then
    mkdir -p "$builddir"
    work="$(readlink -f "$builddir")"
    [[ -w "$work" ]] || { echo "--builddir $work is not writable" >&2; exit 1; }
else
    work="$(mktemp -d "$tmpbase/$tmpprefix.XXXXXXXX")"
    trap 'rm -rf "$work"' EXIT
fi

for name in "${pkgs[@]}"; do
    if [[ $force -eq 0 ]] && compgen -G "$repo/${name}-[0-9]*.pkg.tar.zst" >/dev/null; then
        echo ">> $name: already built, skipping (use --force to rebuild)"
        continue
    fi
    echo ">> $name: cloning + building"
    rm -rf "$work/$name"
    git clone --depth 1 "https://aur.archlinux.org/${name}.git" "$work/$name"
    (
        cd "$work/$name"
        # -s: pull deps, -c: clean, -f: overwrite, --noconfirm: unattended
        makepkg -scf --noconfirm
        mv ./*.pkg.tar.zst "$repo"/
    )
done

# Drop packages that are no longer in $pkgs so the repo db only ever
# describes the current list.
for f in "$repo"/*.pkg.tar.zst; do
    [[ -e "$f" ]] || continue
    base="$(basename "$f")"; keep=0
    for name in "${pkgs[@]}"; do
        [[ "$base" == "$name"-[0-9]* ]] && { keep=1; break; }
    done
    [[ $keep -eq 1 ]] || { echo ">> pruning stale $base"; rm -f "$f"; }
done

echo ">> refreshing $dbname repo db"
rm -f "$repo/$dbname.db"* "$repo/$dbname.files"*
repo-add "$repo/$dbname.db.tar.zst" "$repo"/*.pkg.tar.zst

echo
echo "staged in $repo :"
ls -1 "$repo"/*.pkg.tar.zst
echo
echo "now run ./build.sh"
