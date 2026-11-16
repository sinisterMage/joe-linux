# Following the book's dos2unix page.
build() {
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
