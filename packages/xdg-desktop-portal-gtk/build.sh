build() {
    mkdir build
    cd build
    # The four optional portals are automatic features; with gnome-desktop,
    # gsettings-desktop-schemas and fontconfig present all of them are built.
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        -D wallpaper=enabled \
        -D settings=enabled \
        -D appchooser=enabled \
        -D lockdown=enabled
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
