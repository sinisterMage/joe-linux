# Not in the book: the newest upstream release, built as its INSTALL says.
build() {
    # --with-layout=default: the engine keeps the user's keyboard layout,
    # as Fedora builds it, instead of switching to the Japanese one (jp).
    # Kasumi (the dictionary editor that the preferences can start) and
    # Anthy's zip code dictionary are not packaged.
    ./configure --prefix=/usr \
        --sysconfdir=/etc \
        --disable-static \
        --with-python=python3 \
        --with-layout=default \
        --disable-installed-tests
    make
}

package() {
    # With DESTDIR set, glib-compile-schemas is not run.
    make DESTDIR="$DESTDIR" install
}
