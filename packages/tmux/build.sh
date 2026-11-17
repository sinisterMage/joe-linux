# Not in the book: the newest upstream release, built as its README says.
build() {
    # utf8proc supplies Unicode width data and jemalloc the allocator.
    # utempter (utmp records for panes) remains unavailable.
    ./configure --prefix=/usr \
        --enable-systemd \
        --enable-sixel \
        --enable-utf8proc \
        --disable-utempter \
        --enable-jemalloc
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
