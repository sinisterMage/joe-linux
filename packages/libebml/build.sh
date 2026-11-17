# Not in the book: the newest upstream release (the 1.4 series; 2.0 is
# not released), built with CMake as its README describes, as a shared
# library (upstream's default is static) with its pkg-config and CMake
# package files. libmatroska and MKVToolNix build on it.
build() {
    cmake -B build -G Ninja \
        -D CMAKE_INSTALL_PREFIX=/usr \
        -D CMAKE_INSTALL_LIBDIR=lib \
        -D CMAKE_BUILD_TYPE=Release \
        -D BUILD_SHARED_LIBS=ON
    ninja -C build
}

package() {
    DESTDIR="$DESTDIR" ninja -C build install
}
