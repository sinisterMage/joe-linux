build() {
    mkdir build
    cd build
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release
    ninja
}

package() {
    cd build
    # No icon cache here: gtk-update-icon-cache belongs to GTK, which ships
    # the trigger for it.
    DESTDIR="$DESTDIR" ninja install
}
