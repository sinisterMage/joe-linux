build() {
    mkdir build
    cd build
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        -D profile=release
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
