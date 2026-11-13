#!/bin/bash
# Assembles a bootable joe Linux disk image from a prepared root tree.
#
#   mkimage.sh --rootfs DIR --kernel FILE --sdboot FILE --out IMAGE
#              [--root-size 8G] [--esp-size 1G] [--cmdline "extra options"]
#
# Layout produced:
#   partition 1  EFI system partition (FAT32): systemd-boot, kernels, entries
#   partition 2  btrfs:
#                  joe/deploy/1   subvolume, the first deployment (mounted at /)
#                  home           subvolume, shared by all deployments
#                  var            subvolume, shared by all deployments
#
# Runs unprivileged: the filesystem images are populated by mkfs.btrfs
# --rootdir and mtools, never mounted. It re-executes itself in a user
# namespace so the files end up root-owned in the image.
set -euo pipefail

here=$(cd "$(dirname "$0")" && pwd)
top=$(dirname "$here")
PATH=$top/build/host-tools/bin:$PATH

if [[ $(id -u) -ne 0 ]]; then
    exec unshare --map-root-user "$0" "$@"
fi

rootfs= kernel= sdboot= out= root_size=8G esp_size=1G extra_cmdline=
while [[ $# -gt 0 ]]; do
    case $1 in
        --rootfs) rootfs=$2; shift 2 ;;
        --kernel) kernel=$2; shift 2 ;;
        --sdboot) sdboot=$2; shift 2 ;;
        --out) out=$2; shift 2 ;;
        --root-size) root_size=$2; shift 2 ;;
        --esp-size) esp_size=$2; shift 2 ;;
        --cmdline) extra_cmdline=$2; shift 2 ;;
        *) echo "unknown option: $1" >&2; exit 2 ;;
    esac
done
for v in rootfs kernel sdboot out; do
    [[ -n ${!v} ]] || { echo "missing --$v" >&2; exit 2; }
done

work=$(mktemp -d "$top/build/images/work.XXXXXX")
trap 'rm -rf "$work"' EXIT

esp_uuid=$(uuidgen)
root_uuid=$(uuidgen)

# --- btrfs -----------------------------------------------------------------
layout=$work/layout
mkdir -p "$layout/joe/deploy" "$layout/home" "$layout/var"
cp -a --reflink=auto "$rootfs" "$layout/joe/deploy/1"
deploy=$layout/joe/deploy/1

# /var and /home are shared subvolumes, so their contents live outside the
# deployment; the deployment keeps empty mount points.
for shared in var home; do
    if [[ -d $deploy/$shared ]]; then
        find "$deploy/$shared" -mindepth 1 -maxdepth 1 -exec mv -t "$layout/$shared" {} +
    fi
    mkdir -p "$deploy/$shared"
done
mkdir -p "$deploy/efi"

# The root itself is deliberately absent: it comes from the kernel command line.
cat > "$deploy/etc/fstab" <<EOF
PARTUUID=$root_uuid  /var   btrfs  subvol=var,noatime   0 0
PARTUUID=$root_uuid  /home  btrfs  subvol=home,noatime  0 0
PARTUUID=$esp_uuid  /efi   vfat   umask=0077           0 2
EOF

truncate -s "$root_size" "$work/root.img"
mkfs.btrfs -q -f -L joe \
    --rootdir "$layout" \
    --subvol rw:joe/deploy/1 --subvol rw:home --subvol rw:var \
    "$work/root.img"

# --- ESP -------------------------------------------------------------------
# Kernels are stored under a name derived from their contents and are never
# overwritten, so a boot entry can never end up pointing at a different kernel.
khash=$(sha256sum "$kernel" | cut -c1-16)
# loglevel=4: errors and worse reach the console; the rest is in the journal.
cmdline="root=PARTUUID=$root_uuid rootfstype=btrfs rootflags=subvol=joe/deploy/1 rw rootwait panic=10 loglevel=4"
[[ -n $extra_cmdline ]] && cmdline="$cmdline $extra_cmdline"

esp=$work/esp
mkdir -p "$esp/EFI/BOOT" "$esp/EFI/systemd" "$esp/loader/entries" "$esp/joe/kernels"
cp "$sdboot" "$esp/EFI/BOOT/BOOTX64.EFI"
cp "$sdboot" "$esp/EFI/systemd/systemd-bootx64.efi"
cp "$kernel" "$esp/joe/kernels/$khash.efi"
printf 'type1\n' > "$esp/loader/entries.srel"
cat > "$esp/loader/loader.conf" <<EOF
timeout 0
editor no
EOF
cat > "$esp/loader/entries/joe-1.conf" <<EOF
title joe Linux (deployment 1)
sort-key joe
version 1
linux /joe/kernels/$khash.efi
options $cmdline
EOF

truncate -s "$esp_size" "$work/esp.img"
mkfs.vfat -F 32 -n JOE-ESP "$work/esp.img" >/dev/null
mcopy -i "$work/esp.img" -s "$esp"/* ::

# --- disk ------------------------------------------------------------------
sector=512
esp_sectors=$(( $(stat -c %s "$work/esp.img") / sector ))
root_sectors=$(( $(stat -c %s "$work/root.img") / sector ))
esp_start=2048
root_start=$(( esp_start + esp_sectors ))
total=$(( root_start + root_sectors + 2048 ))

rm -f "$out"
truncate -s $(( total * sector )) "$out"
sfdisk -q "$out" <<EOF
label: gpt
start=$esp_start, size=$esp_sectors, type=C12A7328-F81F-11D2-BA4B-00A0C93EC93B, uuid=$esp_uuid, name="esp"
start=$root_start, size=$root_sectors, type=4F68BCE3-E8CD-4DB1-96E7-FBCAF984B709, uuid=$root_uuid, name="joe"
EOF
dd if="$work/esp.img" of="$out" bs=1M seek=$(( esp_start * sector / 1048576 )) conv=notrunc,sparse status=none
dd if="$work/root.img" of="$out" bs=1M seek=$(( root_start * sector / 1048576 )) conv=notrunc,sparse status=none

echo "image ready: $out ($(du -h "$out" | cut -f1) on disk)"
