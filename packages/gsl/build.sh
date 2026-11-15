build() {
    # As the book; the HTML manual needs Sphinx and is not built.
    ./configure --prefix=/usr --disable-static
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
