# Following the book's GMime page; upstream SHA256SUMS verified.
build() {
    ./configure --prefix=/usr --libdir=/usr/lib --disable-static \
        --enable-crypto --with-libidn --enable-introspection --enable-vala \
        --disable-gtk-doc
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
