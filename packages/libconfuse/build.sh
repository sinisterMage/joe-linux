# Not in the book: the newest upstream release, built as its INSTALL says.
build() {
    ./configure --prefix=/usr \
        --disable-static \
        --disable-examples
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
