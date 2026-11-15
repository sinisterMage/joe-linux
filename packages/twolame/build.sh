# Not in the book: the newest upstream release (0.4.0), built as its INSTALL
# file says. The manual page is shipped prebuilt, so neither asciidoc nor
# xmlto is needed.
build() {
    ./configure --prefix=/usr \
        --disable-static \
        --enable-sndfile
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
