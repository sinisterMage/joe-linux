build() {
    mkdir build
    cd build
    # The book's options: no README rendered with Lynx. The sound played on
    # volume changes (libcanberra) is stated instead of detected.
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        -D lynx=disabled \
        -D audio-feedback=enabled
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
