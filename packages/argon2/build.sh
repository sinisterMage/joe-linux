# Not in the book: the newest upstream release (upstream has made none since
# 2019), built with its Makefile as README.md describes.
#
# OPTTARGET: the optimised implementation is compiled for the baseline
# x86-64 processor (SSE2) rather than the default -march=native, which would
# tie the package to the build machine. LIBRARY_REL: /usr/lib, not the
# Debian multiarch directory the Makefile picks on x86_64. ARGON2_VERSION
# goes into libargon2.pc.
_make() {
    make OPTTARGET=x86-64 LIBRARY_REL=lib PREFIX=/usr ARGON2_VERSION="$PKG_VERSION" "$@"
}

build() {
    _make
}

package() {
    _make DESTDIR="$DESTDIR" install
    rm "$DESTDIR/usr/lib/libargon2.a"
    install -Dm644 man/argon2.1 "$DESTDIR/usr/share/man/man1/argon2.1"
}
