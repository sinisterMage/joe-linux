# Not in the book: the newest upstream release, built with CMake as its
# README.md says.
build() {
    # The shared library, the cmark program and their manual pages; the
    # tests (BUILD_TESTING, from CTest) are off.
    cmake -B build -G Ninja \
        -D CMAKE_INSTALL_PREFIX=/usr \
        -D CMAKE_INSTALL_LIBDIR=lib \
        -D CMAKE_BUILD_TYPE=Release \
        -D BUILD_SHARED_LIBS=ON \
        -D BUILD_TESTING=OFF \
        -D CMARK_LIB_FUZZER=OFF
    ninja -C build
}

package() {
    DESTDIR="$DESTDIR" ninja -C build install
}
