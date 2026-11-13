build() {
    # The book's options. vwebp needs freeglut and SDL, which have no
    # recipes, so the viewer is switched off explicitly.
    ./configure --prefix=/usr \
        --enable-libwebpmux \
        --enable-libwebpdemux \
        --enable-libwebpdecoder \
        --enable-libwebpextras \
        --enable-swap-16bit-csp \
        --enable-jpeg \
        --enable-png \
        --enable-tiff \
        --enable-gif \
        --disable-gl \
        --disable-sdl \
        --disable-static
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
