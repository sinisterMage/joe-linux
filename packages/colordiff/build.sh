# Not in the book: the newest upstream release, installed as its INSTALL
# says. The manual pages come made.
package() {
    make DESTDIR="$DESTDIR" \
        INSTALL_DIR=/usr/bin \
        MAN_DIR=/usr/share/man/man1 \
        ETC_DIR=/etc \
        install
}
