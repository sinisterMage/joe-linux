#!/bin/bash
# Builds a bootable joe Linux image entirely from joe's own packages.
#
#   mkjoe.sh [--test] --repo NAME,DIR,URL,PUBLIC_KEY [--repo ...] OUT_IMAGE PACKAGE...
#
# Each repository is read from DIR while the image is built and configured as
# URL in the installed system. --test adds what the automated tests need and
# nothing a real installation should have: root logs in on the serial console
# without a password.
set -euo pipefail

here=$(cd "$(dirname "$0")" && pwd)
top=$(dirname "$here")

if [[ $(id -u) -ne 0 ]]; then
    exec unshare --map-root-user "$0" "$@"
fi

test_image=0
repos=()
while [[ $# -gt 0 ]]; do
    case $1 in
        --test) test_image=1; shift ;;
        --repo) repos+=("$2"); shift 2 ;;
        *) break ;;
    esac
done
out=$1
shift
[[ ${#repos[@]} -gt 0 && $# -gt 0 ]] || { echo "usage: mkjoe.sh [--test] --repo NAME,DIR,URL,KEY OUT PACKAGE..." >&2; exit 2; }

dave=$top/dave/zig-out/bin/dave
rootfs=$top/build/joe/rootfs
rm -rf "$rootfs"
mkdir -p "$rootfs/etc/dave/keys"

write_repos() { # write_repos <field index of the location to use>
    {
        echo ".{ .repos = .{"
        for spec in "${repos[@]}"; do
            IFS=, read -r name dir url key <<<"$spec"
            local location=$dir
            [[ $1 == url ]] && location=$url
            echo "    .{ .name = \"$name\", .url = \"$location\" },"
        done
        echo "} }"
    } > "$rootfs/etc/dave/repos.zon"
}

for spec in "${repos[@]}"; do
    IFS=, read -r name dir url key <<<"$spec"
    cp "$key" "$rootfs/etc/dave/keys/$name.pub"
done

# The whole system is one dave transaction into an empty directory.
write_repos dir
"$dave" --root "$rootfs" install "$@"
write_repos url
rm -rf "$rootfs/var/cache/dave"

if [[ $test_image -eq 1 ]]; then
    mkdir -p "$rootfs/etc/systemd/system/serial-getty@ttyS0.service.d"
    cat > "$rootfs/etc/systemd/system/serial-getty@ttyS0.service.d/autologin.conf" <<'EOT'
[Service]
ExecStart=
ExecStart=-/usr/sbin/agetty --autologin root --noclear --keep-baud 115200 %I dumb
EOT
    cat > "$rootfs/root/.bash_profile" <<'EOT'
export PS1='joe# '
export TERM=dumb
unset PROMPT_COMMAND
bind 'set enable-bracketed-paste off' 2>/dev/null
EOT
fi

kernel=$(ls "$rootfs"/usr/lib/modules/*/vmlinuz | sort -V | tail -n 1)
"$here/mkimage.sh" --rootfs "$rootfs" --kernel "$kernel" \
    --sdboot "$rootfs/usr/lib/systemd/boot/efi/systemd-bootx64.efi" \
    --out "$out" --cmdline "console=ttyS0,115200"
