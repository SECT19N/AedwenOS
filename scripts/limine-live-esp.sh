#!/usr/bin/env bash
# Give the live ISO the AedwenOS Limine boot menu (System Surfaces design,
# "Boot, install, first run") instead of archiso's systemd-boot.
#
# archiso has no Limine boot mode, so build.sh builds with systemd-boot and
# then runs this on the finished ISO. UEFI boots the ISO from its EFI system
# partition (GPT partition 2, also the El Torito EFI image), a FAT image that
# already holds the kernel and initramfs. This edits that partition in place
# with mtools: systemd-boot's EFI binaries and loader/ entries are swapped for
# Limine's, plus limine.conf and the card wallpaper. Nothing else in the ISO
# moves, so its partition table and El Torito catalogue stay valid.
#
# The boot entries are built from archiso's own loader entry (kernel,
# initramfs and the archisobasedir=/archisolabel= options it filled in), so
# they follow iso/efiboot/loader/entries/aedwen.conf and profiledef.sh.
#
# Usage: scripts/limine-live-esp.sh ISO AIROOTFS
#   AIROOTFS: the built live root (mkarchiso's $work/x86_64/airootfs), for
#   Limine's EFI binaries and the AedwenOS menu look -- the same versions
#   the installed system gets.
# Needs: mtools, util-linux (partx).
set -euo pipefail

iso=$1
air=$2
limine=$air/usr/share/limine

for f in "$limine/BOOTX64.EFI" "$limine/aedwen-limine.conf" "$limine/aedwen-wallpaper.png"; do
    [[ -f $f ]] || { echo "limine-live-esp: missing $f" >&2; exit 1; }
done

start=$(partx -g -o START -n 2 "$iso")
img="$iso@@$((start * 512))"
export MTOOLS_SKIP_CHECK=1

entry=$(mtype -i "$img" ::/loader/entries/aedwen.conf)
field() { sed -n "s/^$1[[:space:]]\+//p" <<<"$entry"; }
kernel=$(field linux | head -n1)
options=$(field options | head -n1)
[[ -n $kernel && -n $options ]] || { echo "limine-live-esp: can't read archiso's loader entry" >&2; exit 1; }
modules=""
while read -r initrd; do
    [[ -n $initrd ]] && modules+="    module_path: boot():$initrd"$'\n'
done < <(field initrd)

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
cfg=$tmp/limine.conf
{
    cat "$limine/aedwen-limine.conf"
    cat <<EOF

/AedwenOS (live)
    comment: Try AedwenOS without changing this computer, or install it
    protocol: linux
    kernel_path: boot():$kernel
${modules}    cmdline: $options

/AedwenOS (live, safe graphics)
    comment: Basic graphics and boot messages, for when the desktop won't start
    protocol: linux
    kernel_path: boot():$kernel
${modules}    cmdline: ${options/ quiet splash/} nomodeset
EOF
    if mdir -i "$img" ::/shellx64.efi &>/dev/null; then
        cat <<EOF

/UEFI Shell
    protocol: efi
    path: boot():/shellx64.efi
EOF
    fi
} >"$cfg"

# systemd-boot out (its menu would otherwise still be found first), Limine in.
mdel -i "$img" ::/EFI/BOOT/BOOTX64.EFI
mdel -i "$img" ::/EFI/BOOT/BOOTIA32.EFI 2>/dev/null || true
mdeltree -i "$img" ::/loader
mcopy -i "$img" "$limine/BOOTX64.EFI" ::/EFI/BOOT/BOOTX64.EFI
[[ -f $limine/BOOTIA32.EFI ]] && mcopy -i "$img" "$limine/BOOTIA32.EFI" ::/EFI/BOOT/BOOTIA32.EFI
mcopy -i "$img" "$cfg" ::/limine.conf
mcopy -i "$img" "$limine/aedwen-wallpaper.png" ::/limine-wallpaper.png

echo "limine-live-esp: Limine boot menu installed in $(basename "$iso")"
mtype -i "$img" ::/limine.conf | sed -n '/^\//,$p' | sed 's/^/    /'
