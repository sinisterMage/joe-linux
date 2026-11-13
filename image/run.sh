#!/bin/bash
# Boots a joe Linux image in QEMU.
#
#   run.sh [IMAGE]              serial console on this terminal
#                               (default image: build/images/joe.img; leave with Ctrl-A X)
#   run.sh --desktop [IMAGE]    a window with the graphical session
#                               (default image: build/images/joe-desktop.img)
#
# The image is not modified: the VM runs on a copy.
set -euo pipefail

top=$(cd "$(dirname "$0")/.." && pwd)
desktop=0
if [[ ${1:-} == --desktop ]]; then desktop=1; shift; fi
default=joe.img
[[ $desktop -eq 1 ]] && default=joe-desktop.img
image=${1:-$top/build/images/$default}
[[ -e $image ]] || { echo "no image at $image; build it first (see 'make help')" >&2; exit 1; }

work=$top/build/images/run
mkdir -p "$work"
cp --reflink=auto --sparse=always "$image" "$work/disk.img"
cp /usr/share/edk2/x64/OVMF_VARS.4m.fd "$work/OVMF_VARS.fd"

args=(
    -enable-kvm -cpu host -machine q35
    -drive if=pflash,format=raw,readonly=on,file=/usr/share/edk2/x64/OVMF_CODE.4m.fd
    -drive if=pflash,format=raw,file="$work/OVMF_VARS.fd"
    -drive file="$work/disk.img",format=raw,if=virtio
    -netdev user,id=n0 -device virtio-net-pci,netdev=n0
)
if [[ $desktop -eq 1 ]]; then
    # The guest renders in software, so it wants cores and memory.
    exec qemu-system-x86_64 "${args[@]}" -m 6G -smp 8 \
        -device virtio-vga -device virtio-keyboard-pci -device virtio-tablet-pci \
        -device intel-hda -device hda-duplex \
        -display gtk -serial mon:stdio
else
    exec qemu-system-x86_64 "${args[@]}" -m 2G -smp 4 -nographic
fi
