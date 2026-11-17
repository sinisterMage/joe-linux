# Not in the book: the newest upstream release, built as its README.rst
# says.
build() {
    # --enable-lib-only: the library alone, without the example program.
    ./configure --prefix=/usr \
        --libdir=/usr/lib \
        --disable-static \
        --enable-lib-only
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
