#!/bin/bash
# Boots a joe Linux image in QEMU with the serial console on this terminal.
#
#   run.sh [IMAGE]        default: build/images/joe.img
#
# The image is not modified: the VM runs on a copy. Leave with Ctrl-A X.
set -euo pipefail

top=$(cd "$(dirname "$0")/.." && pwd)
image=${1:-$top/build/images/joe.img}
[[ -e $image ]] || { echo "no image at $image; run 'make image' first" >&2; exit 1; }

work=$top/build/images/run
mkdir -p "$work"
cp --reflink=auto --sparse=always "$image" "$work/disk.img"
cp /usr/share/edk2/x64/OVMF_VARS.4m.fd "$work/OVMF_VARS.fd"

exec qemu-system-x86_64 \
    -enable-kvm -cpu host -machine q35 -m 2G -smp 4 \
    -drive if=pflash,format=raw,readonly=on,file=/usr/share/edk2/x64/OVMF_CODE.4m.fd \
    -drive if=pflash,format=raw,file="$work/OVMF_VARS.fd" \
    -drive file="$work/disk.img",format=raw,if=virtio \
    -netdev user,id=n0 -device virtio-net-pci,netdev=n0 \
    -nographic
