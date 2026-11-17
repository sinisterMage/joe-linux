# Following the book's gtk-vnc page.
build() {
    mkdir build
    cd build
    # The API reference needs gi-docgen.
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        -D introspection=enabled \
        -D with-vala=enabled \
        -D pulseaudio=enabled \
        -D sasl=enabled \
        -D gi-docs=disabled
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
