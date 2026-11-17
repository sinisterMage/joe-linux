# Not in the book: the newest upstream release, built with CMake as its
# README_cmake describes: the shared library libhpdf, with zlib and libpng
# support, without the examples.
build() {
    cmake -B build -G Ninja \
        -D CMAKE_INSTALL_PREFIX=/usr \
        -D CMAKE_INSTALL_LIBDIR=lib \
        -D CMAKE_BUILD_TYPE=Release \
        -D BUILD_SHARED_LIBS=ON \
        -D LIBHPDF_EXAMPLES=OFF
    ninja -C build
}

package() {
    DESTDIR="$DESTDIR" ninja -C build install
}
