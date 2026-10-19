#!/usr/bin/env bash
# AedwenOS: write the installed system's Limine boot entries and register
# Limine with the firmware. Runs once, during a Calamares install, inside the
# target chroot (shellprocess-postinstall.conf), after the fstab module has
# written /etc/fstab and the dracut initramfs exists.
#
# This lives in its own script instead of inline in the shellprocess config:
# Calamares expands every $NAME / ${NAME} in shellprocess commands itself and
# aborts the job on any name it doesn't know -- shell variables and awk's $1
# included. Removed from the target by the last shellprocess step.
set -euo pipefail

ROOT_UUID=$(findmnt -no UUID /)
CMDLINE="root=UUID=$ROOT_UUID rw rootfstype=btrfs rootflags=subvol=@ quiet splash"
[[ -f /etc/aedwen-nvidia-detected ]] && CMDLINE+=" nvidia_drm.modeset=1"
# Hibernation target: the real swap partition Calamares' "suspend" choice
# creates (see partition.conf), already written to /etc/fstab by the
# fstab module by this point. zram (higher priority, see
# /etc/systemd/zram-generator.conf) handles day-to-day swapping instead --
# this partition exists only so `systemctl hibernate` has somewhere to
# write the resume image. No swap line in fstab (user picked "none")
# just means no resume= and hibernate stays unavailable.
SWAP_UUID=$(awk '$3 == "swap" { sub(/^UUID=/, "", $1); print $1; exit }' /etc/fstab)
[[ -n "$SWAP_UUID" ]] && CMDLINE+=" resume=UUID=$SWAP_UUID"
# Fallback entry ("AedwenOS · fallback" in the design): same kernel and
# initramfs (dracut builds a generic, non-host-only image anyway), but
# boot messages instead of the splash and nomodeset, so a broken GPU
# driver can't stop you reaching a console to fix it.
FALLBACK_CMDLINE="root=UUID=$ROOT_UUID rw rootfstype=btrfs rootflags=subvol=@ nomodeset"
# Global look (timeout, wallpaper, colours) is shared with the live
# ISO's menu: scripts/generate-limine-wallpaper.py writes it.
cp /usr/share/limine/aedwen-limine.conf /boot/limine.conf
cat >> /boot/limine.conf <<EOF

/AedwenOS (linux-zen)
    protocol: linux
    kernel_path: boot():/vmlinuz-linux-zen
    module_path: boot():/initramfs-linux-zen.img
    cmdline: $CMDLINE

/AedwenOS (linux-zen, fallback)
    comment: No boot splash and basic graphics, for when the desktop won't start
    protocol: linux
    kernel_path: boot():/vmlinuz-linux-zen
    module_path: boot():/initramfs-linux-zen.img
    cmdline: $FALLBACK_CMDLINE
EOF

# Firmware boot entry. Best effort: some firmware (and VMs without NVRAM)
# refuse it, and BOOTX64.EFI at the fallback path still boots.
ESP=$(findmnt -no SOURCE /boot)
DISK=/dev/$(lsblk -no PKNAME "$ESP" | head -1)
PART=$(lsblk -no PARTN "$ESP" | head -1)
efibootmgr --create --disk "$DISK" --part "$PART" \
  --label AedwenOS --loader '\EFI\BOOT\BOOTX64.EFI' --unicode || true
