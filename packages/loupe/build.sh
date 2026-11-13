build() {
    mkdir build
    cd build
    # The book runs meson with no options. meson gives cargo a home of its
    # own under the build directory and cargo fetches the crates there
    # (Cargo.lock pins them).
    # - x11: only adds X11 window handles for the portals; the desktop is
    #   Wayland only.
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        -D profile=release \
        -D x11=disabled
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
    # The book's last step removes Eye of GNOME's desktop entry so that
    # Loupe is the image viewer offered; eog does not exist here.
}
