prepare() {
    # Do not install the static library.
    sed -i 's/aom aom_static/aom/' cmake/aom_install.cmake
}

build() {
    mkdir aom-build
    cd aom-build
    # The book's options, plus: lib rather than lib64, nasm named (yasm
    # would be preferred and has no recipe), and no unit tests.
    cmake -D CMAKE_INSTALL_PREFIX=/usr \
        -D CMAKE_INSTALL_LIBDIR=lib \
        -D CMAKE_BUILD_TYPE=Release \
        -D BUILD_SHARED_LIBS=1 \
        -D ENABLE_DOCS=no \
        -D ENABLE_TESTS=no \
        -D ENABLE_NASM=yes \
        -G Ninja ..
    ninja
}

package() {
    cd aom-build
    DESTDIR="$DESTDIR" ninja install
}
