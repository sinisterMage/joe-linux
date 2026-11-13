build() {
    mkdir build
    cd build
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        -D profile=default
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
