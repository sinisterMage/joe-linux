build() {
    mkdir -p build
    cd build
    # Only XML files and a pkg-config file are installed. The tests, which are
    # not run, would compile every protocol with wayland-scanner.
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        -D tests=false
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
