# Following the book's GPGME page. Since 2.0 the C++ and Qt bindings
# are separate projects (gpgmepp, qgpgme), so this is the C library, its
# tools and the Common Lisp binding's sources.
build() {
    mkdir -p build
    cd build
    ../configure --prefix=/usr --disable-static
    make
}

package() {
    cd build
    make DESTDIR="$DESTDIR" install
}
