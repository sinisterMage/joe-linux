build() {
    mkdir build
    cd build
    # --wrap-mode=nodownload: the tarball names GTK, libadwaita,
    # GtkSourceView and libspelling as subprojects to fetch when missing.
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        --wrap-mode=nodownload \
        -D editorconfig=enabled \
        -D development=false
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
