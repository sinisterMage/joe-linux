build() {
    mkdir -p build
    cd build
    # The documentation needs doxygen and the tests need check; neither is part
    # of joe Linux.
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        -D documentation=disabled \
        -D tests=disabled
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
