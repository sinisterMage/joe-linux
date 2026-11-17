# Not in the book: the newest upstream release, built with CMake as its
# documentation describes.
build() {
    # A shared library with the default (char, non-compact) interface, as
    # other distributions build it; no tests.
    cmake -B build -G Ninja \
        -D CMAKE_INSTALL_PREFIX=/usr \
        -D CMAKE_INSTALL_LIBDIR=lib \
        -D CMAKE_BUILD_TYPE=Release \
        -D BUILD_SHARED_LIBS=ON \
        -D PUGIXML_BUILD_TESTS=OFF
    ninja -C build
}

package() {
    DESTDIR="$DESTDIR" ninja -C build install
}
