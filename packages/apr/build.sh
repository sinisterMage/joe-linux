# Following the book's Apr page.
build() {
    ./configure --prefix=/usr \
        --disable-static \
        --with-installbuilddir=/usr/share/apr-1/build
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
