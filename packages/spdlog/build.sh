# Not in the book: the newest upstream release, built with CMake as its
# README describes. Upstream publishes no checksum for the archive.
build() {
    mkdir build
    cd build
    # A shared library using the system fmt rather than the copy bundled
    # in its headers. No example, tests or benchmarks.
    cmake -D CMAKE_INSTALL_PREFIX=/usr \
        -D CMAKE_INSTALL_LIBDIR=lib \
        -D CMAKE_BUILD_TYPE=Release \
        -D SPDLOG_BUILD_SHARED=ON \
        -D SPDLOG_FMT_EXTERNAL=ON \
        -D SPDLOG_BUILD_EXAMPLE=OFF \
        -D SPDLOG_BUILD_TESTS=OFF \
        -D SPDLOG_BUILD_BENCH=OFF \
        -G Ninja ..
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
