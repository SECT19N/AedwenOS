#!/usr/bin/env bash
# Build the AedwenOS ISO from scratch inside a clean archlinux container --
# what .github/workflows/release.yml runs. It sets up the build host
# (archiso, chaotic-aur key + mirrorlist, a non-root makepkg user), then runs
# the same two scripts as a local build: scripts/build-localrepo.sh and
# build.sh. Leaves the ISO and its .sha256 in $BUILD_ROOT/out.
#
#   docker run --rm --privileged \
#       -e HOST_UID="$(id -u)" \
#       -v "$PWD":/src -v /some/ext4/dir:/build \
#       archlinux:latest bash /src/scripts/ci-build.sh
#
# /build must be on ext4/btrfs/xfs (mkarchiso's work dir lives there; see
# build.sh). HOST_UID is the owner of the /src checkout: makepkg runs as a
# user with that UID so it can read/write packages/ and iso/localrepo/
# without chowning the checkout.
set -euo pipefail

src="$(dirname "$(dirname "$(readlink -f "$0")")")"
build="${BUILD_ROOT:-/build}"
host_uid="${HOST_UID:-1000}"

[[ $EUID -eq 0 ]] || { echo "ci-build: run as root inside the container" >&2; exit 1; }

echo ">> preparing build host"
pacman-key --init
pacman-key --populate archlinux
pacman -Syu --noconfirm --needed base-devel git sudo archiso mtools util-linux

# chaotic-aur (for paru on the ISO) -- see iso/pacman.conf. Keyservers are
# flaky from CI runners, so try a few.
chaotic_key=3056513887B78AEB
for ks in keyserver.ubuntu.com keys.openpgp.org pgp.mit.edu; do
    pacman-key --recv-key "$chaotic_key" --keyserver "$ks" && break
    echo ">> keyserver $ks failed, trying the next" >&2
done
pacman-key --list-keys "$chaotic_key" >/dev/null
pacman-key --lsign-key "$chaotic_key"
pacman -U --noconfirm \
    'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' \
    'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'

# makepkg refuses root; build-localrepo.sh calls sudo itself for build deps.
if ! id -u builder &>/dev/null; then
    useradd -m -u "$host_uid" builder
fi
echo 'builder ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/builder
chmod 440 /etc/sudoers.d/builder

mkdir -p "$build/pkgbuild" "$build/work" "$build/out" "$src/iso/localrepo"
chown builder: "$build/pkgbuild" "$src/iso/localrepo"

echo ">> building local repo packages"
sudo -u builder -H env TMPDIR="$build/pkgbuild" bash "$src/scripts/build-localrepo.sh"

# Date the ISO by its commit, not by when CI happened to run.
SOURCE_DATE_EPOCH="$(git -C "$src" -c safe.directory="$src" log -1 --format=%ct)"
export SOURCE_DATE_EPOCH

echo ">> building ISO"
WORK="$build/work" OUT="$build/out" bash "$src/build.sh"

iso="$(ls -t "$build/out"/*.iso | head -n1)"
name="$(basename "$iso")"
case "$name" in
    *-dirty-*|*-gunknown*)
        echo "ci-build: refusing to publish '$name' (dirty tree or unknown commit)" >&2
        exit 1 ;;
esac

# Written from inside out/ so `sha256sum -c` works next to the download.
(cd "$build/out" && sha256sum "$name" > "$name.sha256")
chown "$host_uid" "$build/out"/*
echo ">> done:"
cat "$build/out/$name.sha256"
