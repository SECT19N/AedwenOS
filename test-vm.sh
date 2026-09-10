#!/usr/bin/env bash
# Boot the most recent ./out/*.iso in QEMU.
#
#   ./test-vm.sh                 # UEFI boot (OVMF), GTK + virgl
#   ./test-vm.sh --bios          # legacy BIOS boot (syslinux)
#   ./test-vm.sh --serial        # mirror kernel console to this terminal
#   ./test-vm.sh --direct        # bypass the bootloader: qemu -kernel/-initrd
#                                #   with a verbose cmdline (best for panics)
#   ./test-vm.sh --std           # plain -vga std instead of virtio-gl
#
# Flags combine, e.g.  ./test-vm.sh --bios --serial --std
set -euo pipefail

here="$(dirname "$(readlink -f "$0")")"
iso="$(ls -t "$here"/out/*.iso 2>/dev/null | head -1 || true)"
[[ -n "$iso" ]] || { echo "no ISO in ./out -- run ./build.sh first"; exit 1; }

mode="uefi" serial=0 direct=0 vga="gl"
for a in "$@"; do
    case "$a" in
        --bios)   mode="bios" ;;
        --serial) serial=1 ;;
        --direct) direct=1 ;;
        --std)    vga="std" ;;
        *) echo "unknown flag: $a" >&2; exit 2 ;;
    esac
done

args=(
    -enable-kvm
    -cpu host
    -smp 4
    -m 4G
    -machine q35
    -device intel-hda -device hda-output
    -no-reboot                       # stop on panic so the screen stays readable
)

case "$vga" in
    gl)  args+=(-device virtio-vga-gl -display gtk,gl=on) ;;
    std) args+=(-vga std -display gtk) ;;
esac

if [[ $serial -eq 1 ]]; then
    # kernel console on the same terminal; Ctrl-A X to quit, Ctrl-A C for monitor
    args+=(-serial mon:stdio)
fi

if [[ "$mode" == "uefi" ]]; then
    # Use the plain (non-secboot) 4M build and its MATCHING vars template.
    # Grabbing OVMF_CODE.secboot.*.fd by accident boots with Secure Boot on,
    # which rejects archiso's unsigned systemd-boot / kernel.
    for c in /usr/share/edk2/x64/OVMF_CODE.4m.fd \
             /usr/share/edk2/x64/OVMF_CODE.fd \
             /usr/share/OVMF/OVMF_CODE.4m.fd \
             /usr/share/OVMF/x64/OVMF_CODE.4m.fd; do
        [[ -f "$c" ]] && { ovmf="$c"; break; }
    done
    [[ -n "${ovmf:-}" ]] || { echo "install 'edk2-ovmf' (non-secboot OVMF_CODE not found)"; exit 1; }
    vars="${ovmf/OVMF_CODE/OVMF_VARS}"
    [[ -f "$vars" ]] || vars="$(dirname "$ovmf")/OVMF_VARS.4m.fd"
    cp "$vars" /tmp/aedwen_OVMF_VARS.fd
    args+=(-drive if=pflash,format=raw,readonly=on,file="$ovmf"
           -drive if=pflash,format=raw,file=/tmp/aedwen_OVMF_VARS.fd)
fi

if [[ $direct -eq 1 ]]; then
    # Pull the kernel + initramfs straight out of the ISO and boot them with a
    # loud cmdline. This skips syslinux/systemd-boot entirely, so it isolates
    # "bootloader problem" from "kernel/initramfs problem".
    lbl="$(blkid -o value -s LABEL "$iso" 2>/dev/null || true)"
    : "${lbl:=AEDWEN_$(date +%Y%m)}"
    tmp="$(mktemp -d)"
    bsdtar -C "$tmp" -xf "$iso" aedwen/boot/x86_64/vmlinuz-linux-zen \
                                aedwen/boot/x86_64/initramfs-linux-zen.img
    args+=(
        -kernel "$tmp/aedwen/boot/x86_64/vmlinuz-linux-zen"
        -initrd "$tmp/aedwen/boot/x86_64/initramfs-linux-zen.img"
        -append "archisobasedir=aedwen archisolabel=$lbl \
                 console=tty0 console=ttyS0,115200 loglevel=7 \
                 rd.udev.log_level=debug rd.debug systemd.log_level=debug \
                 nomodeset"
    )
    echo "direct boot, label=$lbl"
else
    args+=(-cdrom "$iso" -boot d)
fi

echo "Booting $iso ($mode)${serial:+ +serial}"
exec qemu-system-x86_64 "${args[@]}"
