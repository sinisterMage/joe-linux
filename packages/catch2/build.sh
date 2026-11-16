# Not in the book: the newest upstream release, built with CMake as its
# docs/cmake-integration.md says. Catch2 3 is a compiled library; it is
# built shared (BUILD_SHARED_LIBS), which upstream supports on Linux, rather
# than as the static libraries it defaults to. The CMake helpers
# (catch_discover_tests and the others) and debugger scripts are installed
# with it.
build() {
    cmake -B build -G Ninja \
        -D CMAKE_INSTALL_PREFIX=/usr \
        -D CMAKE_INSTALL_LIBDIR=lib \
        -D CMAKE_BUILD_TYPE=Release \
        -D BUILD_SHARED_LIBS=ON \
        -D BUILD_TESTING=OFF \
        -D CATCH_DEVELOPMENT_BUILD=OFF \
        -D CATCH_INSTALL_DOCS=OFF \
        -D CATCH_INSTALL_EXTRAS=ON
    ninja -C build
}

package() {
    DESTDIR="$DESTDIR" ninja -C build install
}
