#!/usr/bin/env bash
# shellcheck disable=SC2034
#
# AedwenOS live/install ISO profile (archiso).
# Derived from the upstream `releng` profile, trimmed to a barebones set.

iso_name="aedwenos"
iso_label="AEDWEN_$(date --date="@${SOURCE_DATE_EPOCH:-$(date +%s)}" +%Y%m)"
iso_publisher="AedwenOS <https://example.invalid>"
iso_application="AedwenOS Live/Install medium"
# GIT_HASH/GIT_DIRTY (set by build.sh from the current commit) tie the ISO to
# the exact source it was built from and keep same-day rebuilds from
# overwriting each other's output file; default to "unknown" for a direct
# `mkarchiso` invocation outside build.sh.
iso_version="$(date --date="@${SOURCE_DATE_EPOCH:-$(date +%s)}" +%Y.%m.%d)-g${GIT_HASH:-unknown}${GIT_DIRTY:-}"
install_dir="aedwen"
buildmodes=('iso')

# NOTE: archiso ships no native Limine bootmode. syslinux (BIOS) + systemd-boot
# (UEFI) are used here purely to get a bootable test image. Limine is installed
# on the *target* system by the installer -- that is where it matters.
bootmodes=('bios.syslinux.mbr'
           'bios.syslinux.eltorito'
           'uefi-x64.systemd-boot.esp'
           'uefi-x64.systemd-boot.eltorito')

arch="x86_64"
pacman_conf="pacman.conf"
airootfs_image_type="squashfs"
# FAST=1 (set by `build.sh --fast`) trades compression ratio for build speed
# -- level 19 is thorough but slow, fine for a real release, painful when
# iterating on every VM test. Level 3 is zstd's fast-but-still-decent default.
if [[ "${FAST:-0}" == 1 ]]; then
    airootfs_image_tool_options=('-comp' 'zstd' '-Xcompression-level' '3' '-b' '1M')
else
    airootfs_image_tool_options=('-comp' 'zstd' '-Xcompression-level' '19' '-b' '1M')
fi
bootstrap_tarball_compression=('zstd' '-c' '-T0' '--auto-threads=logical' '--long' '-19')

file_permissions=(
  ["/etc/shadow"]="0:0:400"
  ["/etc/gshadow"]="0:0:400"
  ["/etc/sudoers.d/10-live"]="0:0:440"
  ["/root"]="0:0:750"
  ["/usr/local/bin/aedwen-live-setup"]="0:0:755"
  ["/usr/local/bin/aedwen-live-setup-extras"]="0:0:755"
  ["/usr/local/bin/aedwen-install"]="0:0:755"
  ["/usr/local/bin/aedwen-dracut.sh"]="0:0:755"
  ["/root/customize_airootfs.sh"]="0:0:755"
)
