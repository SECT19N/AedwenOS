# Sourced by startplasma before KWin starts. In a virtual machine, make
# screen edges (top-left hot corner -> Overview, revealing a hidden dock)
# fire on first contact.
#
# KWin normally pushes the cursor 1 px back off the edge and waits for a
# second push. VM mouse integration (VirtualBox, VMware, QEMU tablet) is an
# absolute pointer: once the host cursor reaches the corner of the VM window
# the guest gets no further motion, so the second push never comes and the
# corner only glows. With no push-back KWin activates directly.
#
# Written into the user's kwinrc only while the key is unset, so a value
# chosen in System Settings stays; real hardware is left alone.
if command -v systemd-detect-virt >/dev/null 2>&1 && systemd-detect-virt --vm --quiet; then
    if [ -z "$(kreadconfig6 --file kwinrc --group Windows --key ElectricBorderPushbackPixels 2>/dev/null)" ]; then
        kwriteconfig6 --file kwinrc --group Windows --key ElectricBorderPushbackPixels 0
    fi
fi
