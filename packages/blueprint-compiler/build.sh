build() {
    mkdir build
    cd build
    # docs needs sphinx.
    meson setup .. --prefix=/usr --buildtype=release -D docs=false
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
