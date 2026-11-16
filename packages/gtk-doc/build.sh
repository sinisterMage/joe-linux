# Following the book's gtk-doc page (general/gtk-doc).
build() {
    # The tarball has a directory of its own called build.
    mkdir _build
    cd _build
    # --libdir=lib: the CMake modules go in /usr/lib/cmake/GtkDoc.
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        -D tests=false
    ninja
}

package() {
    cd _build
    DESTDIR="$DESTDIR" ninja install
}
