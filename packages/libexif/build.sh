# Following the book's libexif page. The API documentation (Doxygen) is
# not built: the driver removes /usr/share/doc anyway.
build() {
    ./configure --prefix=/usr \
        --disable-static \
        --disable-docs
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
