# Following the book's unixODBC page. The archive is a git tag, so
# autoreconf makes the configure script.
prepare() {
    autoreconf -fiv
}

build() {
    # The book's flags. Line editing with readline (editline has no
    # recipe); the bundled drivers (--enable-drivers) stay off, as
    # upstream's default.
    ./configure --prefix=/usr \
        --sysconfdir=/etc/unixODBC \
        --disable-static \
        --enable-readline \
        --disable-editline \
        --disable-drivers
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
