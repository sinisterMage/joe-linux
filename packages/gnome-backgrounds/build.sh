build() {
    mkdir build
    cd build
    meson setup --prefix=/usr ..
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
