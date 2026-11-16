# Not in the book: the newest upstream release, built with CMake as its
# README.md says. The API documentation (Doxygen, plus a theme fetched from
# the network) is not built.
build() {
    cmake -B build -G Ninja \
        -D CMAKE_INSTALL_PREFIX=/usr \
        -D CMAKE_INSTALL_LIBDIR=lib \
        -D CMAKE_BUILD_TYPE=Release \
        -D BUILD_SHARED_LIBS=ON \
        -D WITH_EXAMPLES=OFF \
        -D UNIT_TESTING=OFF \
        -D CMAKE_DISABLE_FIND_PACKAGE_Doxygen=ON
    ninja -C build
}

package() {
    DESTDIR="$DESTDIR" ninja -C build install
}
