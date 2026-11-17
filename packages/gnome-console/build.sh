# Not in the book: the newest upstream release (GNOME 51), built with its
# meson files (the README gives no build instructions).
build() {
    mkdir build
    cd build
    # --wrap-mode=nodownload: the tarball names GLib, GTK, libadwaita, Pango
    # and VTE as subprojects to fetch when missing.
    # tests=false: the tests also validate the desktop and metainfo files.
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        --wrap-mode=nodownload \
        -D devel=false \
        -D tests=false
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
