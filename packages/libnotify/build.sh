build() {
    mkdir build
    cd build
    # The tests need GTK 4. The notification daemon the book asks for at run
    # time is gnome-shell.
    meson setup .. \
        --prefix=/usr \
        --buildtype=release \
        -D introspection=enabled \
        -D tests=false \
        -D gtk_doc=false \
        -D man=false \
        -D docbook_docs=disabled
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
