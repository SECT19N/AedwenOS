#!/usr/bin/env bash
# Build the packages that Arch dropped from its official repos and stage them in
# iso/localrepo/ so mkarchiso can pull them (see the [aedwen-local] repo in
# iso/pacman.conf).
#
#   ./scripts/build-localrepo.sh            # build missing / outdated pkgs
#   ./scripts/build-localrepo.sh --force    # rebuild everything
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
[[ "${1:-}" == "--force" ]] && force=1

# AUR packages to build, in dependency order.
pkgs=(ckbcomp calamares amazon-corretto-25-bin zed-bin)

mkdir -p "$repo"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

for name in "${pkgs[@]}"; do
    if [[ $force -eq 0 ]] && compgen -G "$repo/${name}-[0-9]*.pkg.tar.zst" >/dev/null; then
        echo ">> $name: already built, skipping (use --force to rebuild)"
        continue
    fi
    echo ">> $name: cloning + building"
    git clone --depth 1 "https://aur.archlinux.org/${name}.git" "$work/$name"
    (
        cd "$work/$name"
        # -s: pull deps, -c: clean, -f: overwrite, --noconfirm: unattended
        makepkg -scf --noconfirm
        mv ./*.pkg.tar.zst "$repo"/
    )
done

echo ">> refreshing $dbname repo db"
rm -f "$repo/$dbname.db"* "$repo/$dbname.files"*
repo-add "$repo/$dbname.db.tar.zst" "$repo"/*.pkg.tar.zst

echo
echo "staged in $repo :"
ls -1 "$repo"/*.pkg.tar.zst
echo
echo "now run ./build.sh"
