# Not in the book: the newest upstream release. uthash is a set of headers
# with no build system; they are installed as distributions install them.
package() {
    install -d "$DESTDIR/usr/include"
    install -m644 src/*.h "$DESTDIR/usr/include/"
}
