# Not in the book: minizip as zlib ships it in contrib/minizip, built with
# the autotools files there (its CMake build needs the CMake package files
# that zlib's configure does not install). The library and its headers
# (/usr/include/minizip) only; the minizip and miniunzip example programs
# are not built.
prepare() {
    cd contrib/minizip
    autoreconf -fi
}

build() {
    cd contrib/minizip
    ./configure --prefix=/usr --disable-static --disable-demos
    make
}

package() {
    cd contrib/minizip
    make DESTDIR="$DESTDIR" install
}
