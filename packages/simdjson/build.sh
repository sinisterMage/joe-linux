# Not in the book: the newest upstream release, built with CMake as its
# README.md says.
build() {
    # Without SIMDJSON_DEVELOPER_MODE only the library is configured: no
    # tests, tools, benchmarks or downloads. Every x86_64 implementation
    # (fallback, westmere, haswell, icelake) is compiled in and the best one
    # is chosen at run time, so the library stays portable.
    cmake -B build -G Ninja \
        -D CMAKE_INSTALL_PREFIX=/usr \
        -D CMAKE_INSTALL_LIBDIR=lib \
        -D CMAKE_BUILD_TYPE=Release \
        -D BUILD_SHARED_LIBS=ON \
        -D SIMDJSON_BUILD_STATIC_LIB=OFF \
        -D SIMDJSON_DEVELOPER_MODE=OFF \
        -D SIMDJSON_ALLOW_DOWNLOADS=OFF
    ninja -C build
}

package() {
    DESTDIR="$DESTDIR" ninja -C build install
}
