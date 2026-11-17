# Following the book's gnome-shell-extensions page.
build() {
    mkdir build
    cd build
    # extension_set=all, as the book says: every extension is installed;
    # none is enabled until the user turns it on. classic_mode stays off
    # (the GNOME Classic session files).
    meson setup .. \
        --prefix=/usr \
        --buildtype=release \
        -D extension_set=all \
        -D classic_mode=false
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
