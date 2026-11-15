build() {
    cd libraries/liblmdb
    # prefix is given here too: lmdb.pc is written while building.
    make prefix=/usr
    # The static library is not installed.
    sed -i 's| liblmdb.a||' Makefile
}

package() {
    cd libraries/liblmdb
    make prefix=/usr DESTDIR="$DESTDIR" install
    # make builds lmdb.pc but does not install it; BIND and Samba look for
    # it before falling back to a header check.
    install -Dm644 lmdb.pc "$DESTDIR/usr/lib/pkgconfig/lmdb.pc"
}
