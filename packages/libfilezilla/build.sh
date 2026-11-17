# Not in the book: the newest upstream release, built as its INSTALL says.
build() {
    # Message catalogs are built; the Doxygen API reference is not.
    ./configure --prefix=/usr \
        --disable-static \
        --enable-locales \
        --disable-doxygen-doc
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
