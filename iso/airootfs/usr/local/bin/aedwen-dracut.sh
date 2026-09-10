#!/usr/bin/env bash
#
# AedwenOS: (re)generate dracut initramfs images using Arch pkgbase naming
# (/boot/initramfs-<pkgbase>.img -- e.g. initramfs-linux-zen.img) and copy the
# matching kernel to /boot/vmlinuz-<pkgbase>, so the filenames the Limine entry
# points at stay stable across kernel upgrades.
#
# On Arch, the vmlinuz copy and the initramfs build are normally done by
# mkinitcpio's pacman hooks. AedwenOS removes mkinitcpio on the installed system
# and uses dracut, so this helper does both jobs.
#
# Driven by the pacman hooks in /etc/pacman.d/hooks/*dracut* (which pass the
# changed module paths on stdin via NeedsTargets). Can also be run by hand:
#
#   aedwen-dracut.sh install   # rebuild for kernels named on stdin
#   aedwen-dracut.sh remove    # delete boot files for kernels named on stdin
#   aedwen-dracut.sh all       # rebuild for every installed kernel
#
set -euo pipefail

cmd="${1:-all}"

build() {  # $1 = kver, $2 = pkgbase
    echo ":: dracut: /boot/{vmlinuz,initramfs}-${2} (kernel ${1})"
    install -Dm644 "/usr/lib/modules/${1}/vmlinuz" "/boot/vmlinuz-${2}"
    dracut --force --quiet --kver "$1" "/boot/initramfs-${2}.img"
}

purge() {  # $1 = pkgbase
    echo ":: dracut: removing /boot/{vmlinuz,initramfs}-${1}"
    rm -f "/boot/vmlinuz-${1}" "/boot/initramfs-${1}.img"
}

if [[ "$cmd" == all ]]; then
    for kdir in /usr/lib/modules/*/; do
        [[ -e "${kdir}pkgbase" ]] || continue
        kver="${kdir#/usr/lib/modules/}"; kver="${kver%/}"
        read -r pkgbase < "${kdir}pkgbase"
        build "$kver" "$pkgbase"
    done
    exit 0
fi

while read -r target; do
    target="${target#/}"
    [[ "$target" == usr/lib/modules/*/pkgbase ]] || continue
    kver="${target#usr/lib/modules/}"; kver="${kver%/pkgbase}"
    read -r pkgbase < "/$target"   # pkgbase file is present for both install and PreTransaction remove
    case "$cmd" in
        install) build "$kver" "$pkgbase" ;;
        remove)  purge "$pkgbase" ;;
    esac
done
