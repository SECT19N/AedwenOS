#!/usr/bin/env bash
# Boot the most recent ./out/*.iso in QEMU.
#
#   ./test-vm.sh            # UEFI boot (OVMF)
#   ./test-vm.sh --bios     # legacy BIOS boot
set -euo pipefail

here="$(dirname "$(readlink -f "$0")")"
iso="$(ls -t "$here"/out/*.iso 2>/dev/null | head -1 || true)"
[[ -n "$iso" ]] || { echo "no ISO in ./out -- run ./build.sh first"; exit 1; }

mode="uefi"
[[ "${1:-}" == "--bios" ]] && mode="bios"

args=(
    -enable-kvm
    -cpu host
    -smp 4
    -m 4G
    -machine q35
    -device virtio-vga-gl -display gtk,gl=on
    -device intel-hda -device hda-output
    -cdrom "$iso"
    -boot d
)

if [[ "$mode" == "uefi" ]]; then
    ovmf="$(find /usr/share -name 'OVMF_CODE*.fd' 2>/dev/null | head -1)"
    [[ -n "$ovmf" ]] || { echo "install 'edk2-ovmf'"; exit 1; }
    cp "$(dirname "$ovmf")"/OVMF_VARS*.fd /tmp/aedwen_OVMF_VARS.fd
    args+=(-drive if=pflash,format=raw,readonly=on,file="$ovmf"
           -drive if=pflash,format=raw,file=/tmp/aedwen_OVMF_VARS.fd)
fi

echo "Booting $iso ($mode)"
exec qemu-system-x86_64 "${args[@]}"
