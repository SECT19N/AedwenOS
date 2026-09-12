#!/usr/bin/env bash
# AedwenOS: install a proprietary driver only for the one vendor where Mesa/
# nouveau meaningfully falls short. amdgpu (AMD) and i915 (Intel) are already
# complete, in-kernel, and Mesa-backed -- nothing to do for those. This
# detects nvidia via lspci and, if found, installs nvidia-open-dkms + early
# KMS config. Runs once, during install, inside the target chroot; DKMS + the
# existing dracut pacman hooks (90-dracut-install.hook) keep the module
# rebuilt on every future kernel upgrade after that -- no ongoing maintenance.
#
# nvidia-open-dkms covers Turing (GTX 16xx / RTX 20xx) and newer, which is the
# large majority of nvidia hardware in use. Older cards need nvidia-dkms
# instead -- not auto-selected here since that needs a GPU-generation lookup
# table this project doesn't maintain; swap the package by hand if so.
set -euo pipefail

rm -f /etc/aedwen-nvidia-detected

# Vendor 10de (nvidia), display-controller classes (03xx) only -- excludes
# nvidia's onboard audio/USB-c controllers, which share the vendor ID.
if ! lspci -d 10de:: -nn | grep -qE '\[03[0-9a-f]{2}\]'; then
    echo ":: gpu-setup: no nvidia GPU detected, nothing to do"
    exit 0
fi

echo ":: gpu-setup: nvidia GPU detected, installing nvidia-open-dkms"
pacman -S --noconfirm --needed nvidia-open-dkms nvidia-utils lib32-nvidia-utils

# Early KMS: load the nvidia modules from the initramfs so plymouth/SDDM start
# on KMS instead of falling back to a VESA/EFI framebuffer.
install -Dm644 /dev/stdin /etc/dracut.conf.d/nvidia.conf <<'EOF'
force_drivers+=" nvidia nvidia_modeset nvidia_uvm nvidia_drm "
EOF

# Read by the limine.conf writer (aedwen-install / shellprocess-postinstall)
# to append nvidia_drm.modeset=1 to the kernel cmdline.
touch /etc/aedwen-nvidia-detected
