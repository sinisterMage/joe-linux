# Not in the book: the newest upstream release, built with its CMake files
# (the archive of the tag has no configure script). The parser and scanner
# are generated sources in the archive, so bison and flex are not needed.
build() {
    # The C and C++ libraries with their pkg-config and CMake files; no
    # examples, tests or fuzzers.
    cmake -B build -G Ninja \
        -D CMAKE_INSTALL_PREFIX=/usr \
        -D CMAKE_INSTALL_LIBDIR=lib \
        -D CMAKE_BUILD_TYPE=Release \
        -D BUILD_SHARED_LIBS=ON \
        -D BUILD_CXX=ON \
        -D BUILD_EXAMPLES=OFF \
        -D BUILD_TESTS=OFF \
        -D BUILD_FUZZERS=OFF
    ninja -C build
}

package() {
    DESTDIR="$DESTDIR" ninja -C build install
}
