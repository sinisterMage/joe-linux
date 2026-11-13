build() {
    mkdir build
    cd build
    # This release has no GTK part any more, whatever the book's dependency
    # list says; the tests are not built.
    meson setup .. \
        --prefix=/usr \
        --buildtype=release \
        -D introspection=enabled \
        -D vapi=true \
        -D tests=false \
        -D docs=false
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
