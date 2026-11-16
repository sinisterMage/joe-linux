# Not in the book: the newest upstream release, built with CMake as its
# README says. Hardware performance counters (libpfm) are off: libpfm
# has no recipe. The comparison scripts (tools/compare.py) are not
# installed: they need NumPy and SciPy, which have no recipe either.
build() {
    cmake -B build -G Ninja \
        -D CMAKE_INSTALL_PREFIX=/usr \
        -D CMAKE_INSTALL_LIBDIR=lib \
        -D CMAKE_BUILD_TYPE=Release \
        -D BUILD_SHARED_LIBS=ON \
        -D BENCHMARK_ENABLE_TESTING=OFF \
        -D BENCHMARK_ENABLE_GTEST_TESTS=OFF \
        -D BENCHMARK_ENABLE_WERROR=OFF \
        -D BENCHMARK_ENABLE_LTO=OFF \
        -D BENCHMARK_ENABLE_LIBPFM=OFF \
        -D BENCHMARK_ENABLE_DOXYGEN=OFF \
        -D BENCHMARK_INSTALL_DOCS=OFF \
        -D BENCHMARK_INSTALL_TOOLS=OFF \
        -D BENCHMARK_DOWNLOAD_DEPENDENCIES=OFF
    ninja -C build
}

package() {
    DESTDIR="$DESTDIR" ninja -C build install
}
