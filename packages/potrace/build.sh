build() {
    # The book's options: the shared libpotrace (Inkscape's Trace Bitmap and
    # bucket fill use it), metric units and A4 paper by default.
    ./configure --prefix=/usr \
        --disable-static \
        --docdir=/usr/share/doc/potrace-1.16 \
        --enable-a4 \
        --enable-metric \
        --with-libpotrace
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
