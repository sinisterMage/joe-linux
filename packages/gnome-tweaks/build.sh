# Following the book's gnome-tweaks page.
build() {
    mkdir build
    cd build
    meson setup .. \
        --prefix=/usr \
        --buildtype=release
    ninja
}

package() {
    cd build
    # The install script byte-compiles the gtweak modules into $DESTDIR.
    DESTDIR="$DESTDIR" ninja install
}
