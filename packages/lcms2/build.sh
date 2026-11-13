build() {
    mkdir -p build
    cd build
    # libjpeg and libtiff are only used by the jpgicc and tificc utilities,
    # which this version does not build by default (-D utils=false).
    meson setup --prefix=/usr .. \
        --libdir=lib \
        --buildtype=release \
        -D jpeg=disabled \
        -D tiff=disabled \
        -D tests=disabled
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
