build() {
    mkdir -p build
    cd build
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
