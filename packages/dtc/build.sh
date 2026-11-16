# Following the book's dtc page. The Python module (pylibfdt) is left out, as
# the book's main instructions do; Valgrind support is only for the test
# suite, which is not built.
build() {
    mkdir build
    cd build
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        --default-library=shared \
        -D python=disabled \
        -D yaml=enabled \
        -D valgrind=disabled \
        -D tests=false
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
