# Not in the book: the newest upstream release of the C library, built with
# CMake as its README.md says.
build() {
    # BUILD_SHARED_LIBS=ON builds the shared library only (no
    # msgpack-c-static); no examples or tests.
    cmake -B build -G Ninja \
        -D CMAKE_INSTALL_PREFIX=/usr \
        -D CMAKE_INSTALL_LIBDIR=lib \
        -D CMAKE_BUILD_TYPE=Release \
        -D BUILD_SHARED_LIBS=ON \
        -D MSGPACK_BUILD_EXAMPLES=OFF \
        -D MSGPACK_BUILD_TESTS=OFF
    ninja -C build
}

package() {
    DESTDIR="$DESTDIR" ninja -C build install
}
