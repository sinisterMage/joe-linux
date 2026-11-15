build() {
    mkdir build
    cd build
    # The book's options, with its recommended introspection and libadwaita
    # stated, bluetooth-sendto built, and no GTK-Doc reference.
    # --wrap-mode=nodownload: libadwaita has a subproject fallback; the
    # system one is used.
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        --wrap-mode=nodownload \
        -D introspection=true \
        -D sendto=true \
        -D gtk_doc=false
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
