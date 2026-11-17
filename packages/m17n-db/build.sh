# Not in the book: the newest upstream release, built as its INSTALL says.
build() {
    ./configure --prefix=/usr \
        --with-charmaps=/usr/share/i18n/charmaps
    make
}

package() {
    # Everything goes to /usr/share/m17n.
    make DESTDIR="$DESTDIR" install
}
