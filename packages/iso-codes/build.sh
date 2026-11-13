build() {
    mkdir -p build
    cd build
    meson setup --prefix=/usr ..
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
