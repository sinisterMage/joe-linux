build() {
    # The book's command. The book's sed only fixes a test, and the tests
    # are not built. The manual pages need latex2man, which joe lacks.
    # Compressed symbol tables are read with liblzma and zlib, stated
    # rather than detected.
    ./configure --prefix=/usr \
        --disable-static \
        --disable-tests \
        --disable-documentation \
        --enable-minidebuginfo \
        --enable-zlibdebuginfo
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
