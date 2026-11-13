build() {
    mkdir -p build
    cd build
    # No doxygen (API documentation); the tests and the demo programs they
    # need are not built.
    meson setup --prefix=/usr .. \
        --libdir=lib \
        --buildtype=release \
        -D docs=disabled \
        -D tests=disabled \
        -D extra-programs=disabled
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
