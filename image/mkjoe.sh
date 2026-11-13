#!/bin/bash
# Builds a bootable joe Linux image entirely from joe's own packages.
#
#   mkjoe.sh [--test] [--overlay DIR] [--root-size SIZE]
#            --repo NAME,DIR,URL,PUBLIC_KEY [--repo ...] OUT_IMAGE PACKAGE...
#
# Each repository is read from DIR while the image is built and configured as
# URL in the installed system. --test also installs joe-test-console, which
# the automated tests need and no real installation should have: root logs in
# on the serial console without a password, and accounts created by test
# packages get the password "joe". --overlay copies a directory tree over the
# installed system, for configuration a particular image needs.
set -euo pipefail

here=$(cd "$(dirname "$0")" && pwd)
top=$(dirname "$here")

if [[ $(id -u) -ne 0 ]]; then
    exec unshare --map-root-user "$0" "$@"
fi

test_image=0
overlay=
root_size=8G
repos=()
while [[ $# -gt 0 ]]; do
    case $1 in
        --test) test_image=1; shift ;;
        --repo) repos+=("$2"); shift 2 ;;
        --overlay) overlay=$2; shift 2 ;;
        --root-size) root_size=$2; shift 2 ;;
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
packages=("$@")
[[ $test_image -eq 1 ]] && packages+=(joe-test-console)
write_repos dir
if [[ $test_image -eq 1 ]]; then
    # systemd-sysusers, run as a trigger, takes passwords for the accounts it
    # creates from credentials. Triggers run inside the new root, so that is
    # where the directory has to be, and how its path has to be given.
    credentials=/run/mkjoe-credentials
    mkdir -p "$rootfs$credentials"
    printf joe > "$rootfs$credentials/passwd.plaintext-password.joe"
    export CREDENTIALS_DIRECTORY=$credentials
fi
"$dave" --root "$rootfs" install "${packages[@]}"
[[ -z ${credentials:-} ]] || rm -rf "${rootfs:?}$credentials"
[[ -z $overlay ]] || cp -a --no-preserve=ownership "$overlay/." "$rootfs/"
write_repos url
rm -rf "$rootfs/var/cache/dave"

kernel=$(ls "$rootfs"/usr/lib/modules/*/vmlinuz | sort -V | tail -n 1)
"$here/mkimage.sh" --rootfs "$rootfs" --kernel "$kernel" \
    --sdboot "$rootfs/usr/lib/systemd/boot/efi/systemd-bootx64.efi" \
    --out "$out" --root-size "$root_size" --cmdline "console=ttyS0,115200"
