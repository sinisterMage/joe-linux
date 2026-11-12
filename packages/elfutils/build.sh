# Only libelf is built and installed; the rest of elfutils is not shipped.
build() {
    ./configure --prefix=/usr \
        --disable-debuginfod \
        --enable-libdebuginfod=dummy
    make -C lib
    make -C libelf
}

package() {
    make -C libelf DESTDIR="$DESTDIR" install
    install -Dm644 config/libelf.pc "$DESTDIR/usr/lib/pkgconfig/libelf.pc"
    rm -f "$DESTDIR/usr/lib/libelf.a"
}
