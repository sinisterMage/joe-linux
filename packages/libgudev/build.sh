build() {
    mkdir build
    cd build
    # The tests need umockdev, which has no recipe.
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        -D introspection=enabled \
        -D vapi=enabled \
        -D tests=disabled \
        -D gtk_doc=false
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
