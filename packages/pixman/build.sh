build() {
    mkdir -p build
    cd build
    # libpng and GTK are only used by the tests and demos, which are not
    # built; OpenMP likewise only speeds up the tests.
    meson setup --prefix=/usr .. \
        --libdir=lib \
        --buildtype=release \
        -D tests=disabled \
        -D demos=disabled \
        -D gtk=disabled \
        -D libpng=disabled \
        -D openmp=disabled
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
