# Not in the book: the newest upstream release, built as its INSTALL says.
build() {
    # The HTML manual comes ready-made in the tarball, so Docutils is not
    # run (it would only go to /usr/share/doc, which the driver removes;
    # Help then opens the online manual). No PDF or API documentation.
    # Built-in plugins, the single-instance socket and the VTE terminal
    # panel are on. Build commands that run Python call python3.
    ./configure --prefix=/usr \
        --disable-static \
        --enable-plugins \
        --enable-socket \
        --enable-vte \
        --disable-binreloc \
        --disable-mac-integration \
        --disable-html-docs \
        --disable-pdf-docs \
        --disable-api-docs \
        --disable-gtkdoc-header \
        --with-python-command=python3
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
