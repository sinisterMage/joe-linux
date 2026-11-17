# Not in the book: the newest upstream release, built with CMake as its
# INSTALL says, without the tests, benchmarks and Doxygen documentation.
build() {
    cmake -B build -G Ninja \
        -D CMAKE_INSTALL_PREFIX=/usr \
        -D CMAKE_INSTALL_LIBDIR=lib \
        -D CMAKE_BUILD_TYPE=Release \
        -D BUILD_SHARED_LIBS=ON \
        -D BUILD_TESTING=OFF \
        -D BUILD_BENCHMARKS=OFF \
        -D BUILD_DOCUMENTATION=OFF
    ninja -C build
}

package() {
    DESTDIR="$DESTDIR" ninja -C build install
}
