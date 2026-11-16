# Not in the book: the newest upstream release (0.6.4, from 2021), built
# with its Makefile as its README says. The Makefile enables programs by
# what it finds, so each is stated: c2xml (libxml2) and semind (SQLite) on;
# test-inspect, a GTK debugging viewer, off; sparse-llvm off, since it is
# written for the LLVM C API from before opaque pointers and does not build
# with LLVM 23; scheck off (Boolector has no recipe).
_make() {
    make PREFIX=/usr \
        HAVE_LIBXML=yes \
        HAVE_SQLITE=yes \
        HAVE_GTK=no \
        HAVE_LLVM=no \
        HAVE_BOOLECTOR=no \
        "$@"
}

build() {
    _make
}

package() {
    _make DESTDIR="$DESTDIR" install
}
