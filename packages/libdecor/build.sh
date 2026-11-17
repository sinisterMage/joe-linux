# Not in the book: the newest upstream release, built with meson as its
# README describes. GNOME's compositor draws no window decorations itself,
# so Wayland programs that do not use GTK or Qt (SDL games, GLFW programs)
# get their title bar from this library. Both plugins are built; the GTK
# one is preferred when GTK 3 is present. The demo programs are not.
build() {
    mkdir build
    cd build
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        -D demo=false \
        -D install_demo=false \
        -D dbus=enabled \
        -D gtk=enabled
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
