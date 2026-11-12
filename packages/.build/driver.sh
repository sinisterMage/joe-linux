#!/bin/bash
# Runs inside the build root, as root in a user namespace with no network.
# Sources /recipe/build.sh and calls, in order:
#
#   unpack    (default: extract $SOURCES/$PKG_SOURCE into the current directory)
#   prepare   (default: nothing)    patches and source fixes
#   build     (default: nothing)    configure and compile
#   package   (required)           install into $DESTDIR
#
# All four run in /build/src. Afterwards the staged tree is tidied the same
# way for every package.
set -euo pipefail
umask 022

unpack() {
    tar -xf "$SOURCES/$PKG_SOURCE" --strip-components=1 --no-same-owner --no-same-permissions
}
prepare() { :; }
build() { :; }

# shellcheck disable=SC1091
source /recipe/build.sh
declare -F package >/dev/null || { echo "build.sh does not define package()" >&2; exit 1; }

# Each step starts in the source directory, whatever the previous one did.
set -x
cd /build/src
[[ -z ${PKG_SOURCE:-} ]] || unpack
cd /build/src
prepare
cd /build/src
build
cd /build/src
package
set +x

cd "$DESTDIR"

# /var is a subvolume shared by every deployment and /run and /tmp are
# temporary file systems, so nothing a package puts there would ever be seen.
# What a program needs there is created at boot by tmpfiles.d.
if [[ $PKG_NAME != joe-filesystem ]]; then
    rm -rf var run tmp
fi

# Libtool archives only cause trouble; documentation readers are not shipped yet.
find . -name '*.la' -delete
rm -rf usr/share/doc usr/share/info usr/share/gtk-doc

# Strip debugging symbols unless the recipe opts out with NOSTRIP=1.
if [[ -z ${NOSTRIP:-} ]]; then
    while IFS= read -r -d '' f; do
        case $(head -c 4 "$f" | od -An -c | tr -d ' ') in
            '177ELF') ;;
            *) case $f in
                   *.a) strip --strip-debug "$f" 2>/dev/null || true ;;
               esac
               continue ;;
        esac
        case $f in
            *.ko | *.ko.*) ;;
            *.o) strip --strip-debug "$f" 2>/dev/null || true ;;
            *) strip --strip-unneeded "$f" 2>/dev/null || true ;;
        esac
    done < <(find . -type f -print0)
fi

# Empty directories that only existed to hold what was removed above.
find . -depth -type d -empty -path './usr/share/*' -delete 2>/dev/null || true
