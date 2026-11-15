# Not in the book: the newest upstream release (0.12), built with its
# configure script.
build() {
    # --disable-http: no libopusurl (Opus streams over HTTP). Nothing here
    # uses it, and its TLS code is written against the OpenSSL 1.x API.
    # --disable-doc: the API reference needs Doxygen.
    ./configure --prefix=/usr \
        --disable-static \
        --disable-http \
        --disable-examples \
        --disable-doc
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
