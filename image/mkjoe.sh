#!/bin/bash
# Superseded by `dave image build` and the specifications in this directory;
# kept for one release because the build machine's joe-build still calls it.
# It turns its arguments into a specification and builds that.
#
#   mkjoe.sh [--test] [--overlay DIR] [--root-size SIZE]
#            --repo NAME,DIR,URL,PUBLIC_KEY [--repo ...] OUT_IMAGE PACKAGE...
set -euo pipefail

here=$(cd "$(dirname "$0")" && pwd)
top=$(dirname "$here")
export PATH=$top/build/host-tools/bin:$PATH

args=() overlay= root_size=8G
while [[ $# -gt 0 ]]; do
    case $1 in
        --test) args+=(--test); shift ;;
        --repo) args+=(--repo "$2"); shift 2 ;;
        --overlay) overlay=$(cd "$2" && pwd); shift 2 ;;
        --root-size) root_size=$2; shift 2 ;;
        *) break ;;
    esac
done
out=$1
shift
[[ $# -gt 0 ]] || { echo "usage: mkjoe.sh [--test] --repo NAME,DIR,URL,KEY OUT PACKAGE..." >&2; exit 2; }

spec_dir=$(mktemp -d)
trap 'rm -rf "$spec_dir"' EXIT
{
    echo ".{"
    echo "    .name = \"$(basename "$out")\","
    printf '    .packages = .{'
    for package in "$@"; do printf ' "%s",' "$package"; done
    echo ' },'
    [[ -z $overlay ]] || echo "    .overlay = \"$overlay\","
    echo "    .root_size = \"$root_size\","
    echo '    .cmdline = "console=ttyS0,115200",'
    echo "}"
} > "$spec_dir/image.zon"
"$top/dave/zig-out/bin/dave" image build "$spec_dir/image.zon" "${args[@]}" --out "$out"
