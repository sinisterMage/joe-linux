# Not in the book: the newest upstream release, built as its README says.
# opus-tools' opusenc is built on it. No example program, no doxygen API
# documentation.
build() {
    ./configure --prefix=/usr \
        --disable-static \
        --disable-examples \
        --disable-doc
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
