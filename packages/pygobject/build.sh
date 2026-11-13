build() {
    mkdir build
    cd build
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        -D pycairo=enabled \
        -D tests=false
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
