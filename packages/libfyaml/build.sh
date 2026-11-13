build() {
    # --without-libclang: the C reflection support is not wanted.
    ./configure --prefix=/usr \
        --disable-static \
        --without-libclang
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
