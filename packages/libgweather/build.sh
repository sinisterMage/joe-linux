build() {
    mkdir build
    cd build
    # gi-docgen does not exist; the tests are not built.
    meson setup .. \
        --prefix=/usr \
        --buildtype=release \
        -D introspection=true \
        -D enable_vala=true \
        -D gtk_doc=false \
        -D tests=false
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
