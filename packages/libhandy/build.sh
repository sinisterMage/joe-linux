build() {
    mkdir build
    cd build
    # The book builds with the defaults; stated here: introspection and the
    # Vala bindings on, no Glade catalogue (Glade does not exist), no
    # GTK-Doc, and neither the tests nor the demo program.
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        -D introspection=enabled \
        -D vapi=true \
        -D glade_catalog=disabled \
        -D gtk_doc=false \
        -D tests=false \
        -D examples=false \
        -D profiling=false
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
