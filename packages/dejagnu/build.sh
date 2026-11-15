build() {
    # The book's HTML and plain-text manuals are documentation only and
    # are left out; the Info manual comes ready-made in the tarball.
    mkdir -v build
    cd build
    ../configure --prefix=/usr
}

package() {
    cd build
    make DESTDIR="$DESTDIR" install
}
