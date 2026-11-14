#!/bin/bash
# Builds the scaffold image with dave installed and an initial set of packages
# from a local repository, for the deployment tests in tests/vm.
#
#   mkscaffold-dave.sh REPO_DIR PUBLIC_KEY REPO_URL OUT_IMAGE PACKAGE...
#
# REPO_DIR is read directly while building; REPO_URL is what the booted system
# is configured to use afterwards.
set -euo pipefail

here=$(cd "$(dirname "$0")" && pwd)
top=$(dirname "$here")
export PATH=$top/build/host-tools/bin:$PATH

if [[ $(id -u) -ne 0 ]]; then
    exec unshare --map-root-user "$0" "$@"
fi

repo_dir=$1 public_key=$2 repo_url=$3 out=$4
shift 4
dave=$top/dave/zig-out/bin/dave
base=$top/build/scaffold/rootfs
rootfs=$top/build/scaffold/rootfs-dave

[[ -d $base ]] || "$here/mkscaffold.sh"
rm -rf "$rootfs"
cp -a --reflink=auto "$base" "$rootfs"
"$here/add-dave.sh" "$rootfs" "$dave"

with=()
for package in "$@"; do with+=(--with "$package"); done
"$dave" image build "$here/scaffold.zon" --tree "$rootfs" \
    --repo "joe,$repo_dir,$repo_url,$public_key" "${with[@]}" --out "$out"
rm -rf "$rootfs"
