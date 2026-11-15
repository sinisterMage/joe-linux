prepare() {
    # Install the manual page uncompressed.
    sed -i "/INSTALL.*gz/s/.gz//" Makefile
}

build() {
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
