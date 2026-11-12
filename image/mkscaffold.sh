#!/bin/bash
# Builds the *scaffold* root filesystem: a throwaway development fixture made
# from this machine's kernel modules and a stock Arch userspace. It exists only
# so the boot, upgrade and rollback mechanics can be exercised in QEMU before
# joe's own packages exist. Nothing from it ever ships in joe Linux.
#
# Runs unprivileged; re-executes itself in a user namespace so that the files
# it creates appear root-owned.
set -euo pipefail

here=$(cd "$(dirname "$0")" && pwd)
top=$(dirname "$here")
scaffold=$top/build/scaffold
tarball=$scaffold/archlinux-bootstrap.tar.zst
rootfs=$scaffold/rootfs
kver=${KVER:-$(uname -r)}

if [[ $(id -u) -ne 0 ]]; then
    exec unshare --map-root-user "$0" "$@"
fi

[[ -f $tarball ]] || { echo "missing $tarball" >&2; exit 1; }

rm -rf "$rootfs" "$scaffold/root.x86_64"
tar --zstd -xf "$tarball" -C "$scaffold" --no-same-owner
mv "$scaffold/root.x86_64" "$rootfs"

# Kernel modules matching the host kernel that the scaffold boots.
mkdir -p "$rootfs/usr/lib/modules"
cp -a --reflink=auto --no-preserve=ownership "/usr/lib/modules/$kver" "$rootfs/usr/lib/modules/"

# btrfs-progs is not in the bootstrap tarball; borrow the host's for manual
# experiments. dave itself talks to btrfs through ioctls and does not need it.
install -m755 /usr/bin/btrfs "$rootfs/usr/bin/btrfs"
for lib in $(ldd /usr/bin/btrfs | awk '$3 ~ /^\// {print $3}'); do
    name=$(basename "$lib")
    [[ -e $rootfs/usr/lib/$name ]] || cp -L "$lib" "$rootfs/usr/lib/$name"
done

echo joe-scaffold > "$rootfs/etc/hostname"

# Root logs in automatically on the serial console; the test harness drives it.
sed -i 's|^root:[^:]*:|root::|' "$rootfs/etc/shadow"
mkdir -p "$rootfs/etc/systemd/system/serial-getty@ttyS0.service.d"
cat > "$rootfs/etc/systemd/system/serial-getty@ttyS0.service.d/autologin.conf" <<'EOF'
[Service]
ExecStart=
ExecStart=-/usr/bin/agetty --autologin root --noclear --keep-baud 115200 %I dumb
EOF

mkdir -p "$rootfs/etc/systemd/network"
cat > "$rootfs/etc/systemd/network/20-wired.network" <<'EOF'
[Match]
Type=ether

[Network]
DHCP=yes
EOF
mkdir -p "$rootfs/etc/systemd/system/multi-user.target.wants"
ln -sf /usr/lib/systemd/system/systemd-networkd.service \
    "$rootfs/etc/systemd/system/multi-user.target.wants/systemd-networkd.service"

# No interactive first-boot questions on the console.
ln -sf /dev/null "$rootfs/etc/systemd/system/systemd-firstboot.service"
ln -sf /usr/share/zoneinfo/UTC "$rootfs/etc/localtime"
echo 'LANG=C.UTF-8' > "$rootfs/etc/locale.conf"

# Modules the host kernel does not build in but the scaffold needs early.
mkdir -p "$rootfs/etc/modules-load.d"
printf 'vfat\nvirtio_net\n' > "$rootfs/etc/modules-load.d/scaffold.conf"

# A quiet, predictable shell for the harness.
cat > "$rootfs/root/.bash_profile" <<'EOF'
export PS1='joe# '
export TERM=dumb
unset PROMPT_COMMAND
bind 'set enable-bracketed-paste off' 2>/dev/null
EOF

mkdir -p "$rootfs/efi"
echo "scaffold rootfs ready: $rootfs ($(du -sh "$rootfs" | cut -f1))"
