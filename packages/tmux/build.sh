# Not in the book: the newest upstream release, built as its README says.
build() {
    # Not available: utf8proc (tmux uses the C library's wcwidth instead),
    # utempter (utmp records for panes), jemalloc. Sixel image support
    # needs nothing extra.
    ./configure --prefix=/usr \
        --enable-systemd \
        --enable-sixel \
        --disable-utf8proc \
        --disable-utempter \
        --disable-jemalloc
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
