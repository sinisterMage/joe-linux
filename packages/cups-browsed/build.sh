# Following the book's cups-browsed page.
build() {
    # The book's options, with Avahi stated (it is required by the book
    # and enabled by default).
    ./configure --prefix=/usr \
        --with-cups-rundir=/run/cups \
        --without-rcdir \
        --enable-avahi \
        --disable-static \
        --docdir=/usr/share/doc/cups-browsed-2.1.1
    make
}

package() {
    make DESTDIR="$DESTDIR" install
    # The book's unit, shipped but not enabled (the book enables it).
    install -v -Dm644 daemon/cups-browsed.service "$DESTDIR/usr/lib/systemd/system/cups-browsed.service"
}
