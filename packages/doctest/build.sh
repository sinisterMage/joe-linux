# Not in the book: the newest upstream release, installed with CMake as its
# doc/markdown/build-systems.md says. Only the headers and the CMake and
# pkg-config files are installed; nothing is compiled.

# The release archive has no top-level directory.
unpack() {
    tar -xf "$SOURCES/$PKG_SOURCE" --no-same-owner --no-same-permissions
}

build() {
    cmake -B build -G Ninja \
        -D CMAKE_INSTALL_PREFIX=/usr \
        -D CMAKE_INSTALL_LIBDIR=lib \
        -D CMAKE_BUILD_TYPE=Release \
        -D DOCTEST_WITH_TESTS=OFF \
        -D DOCTEST_WITH_MAIN_IN_STATIC_LIB=OFF
    ninja -C build
}

package() {
    DESTDIR="$DESTDIR" ninja -C build install
}
