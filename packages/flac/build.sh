build() {
    # --disable-thorough-tests is the book's; it only affects "make check".
    # There is no doxygen: do not try to build the API documentation.
    ./configure --prefix=/usr \
        --disable-static \
        --disable-thorough-tests \
        --disable-doxygen-docs
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
