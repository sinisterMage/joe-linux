build() {
    mkdir build
    cd build
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        -D gobject_types=true \
        -D introspection=enabled \
        -D gtk_doc=false \
        -D tests=false \
        -D installed_tests=false
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
