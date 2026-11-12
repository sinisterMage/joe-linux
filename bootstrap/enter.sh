#!/bin/bash
# Runs a command inside the build root, as root in a user namespace.
#
#   enter.sh [--net] COMMAND...
#
# The build root is mounted read-write at /, the downloaded sources read-only
# at /sources, and build/bootstrap/work at /build. There is no network unless
# --net is given.
set -euo pipefail

top=$(cd "$(dirname "$0")/.." && pwd)
root=$top/build/bootstrap/root
net=--unshare-net
if [[ ${1:-} == --net ]]; then net=; shift; fi

mkdir -p "$top/build/bootstrap/work"
exec bwrap --unshare-user --uid 0 --gid 0 --cap-add ALL $net \
    --unshare-ipc --unshare-uts --hostname joe-build --die-with-parent \
    --bind "$root" / --dev /dev --proc /proc --tmpfs /run --tmpfs /tmp \
    --bind "$top/build/bootstrap/work" /build \
    --ro-bind "$top/build/src" /sources \
    --clearenv --setenv HOME /root --setenv TERM "${TERM:-dumb}" \
    --setenv PATH /usr/bin:/usr/sbin --setenv LC_ALL POSIX \
    --setenv MAKEFLAGS "-j$(nproc)" --setenv FORCE_UNSAFE_CONFIGURE 1 \
    --chdir / "$@"
