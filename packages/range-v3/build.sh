# Not in the book: the newest upstream release (0.12.0 is still the latest
# tag), installed with its CMake files.
build() {
    # Header-only: nothing is compiled once the tests, examples, benchmarks,
    # header checks and documentation are off.
    cmake -B build -G Ninja \
        -D CMAKE_INSTALL_PREFIX=/usr \
        -D CMAKE_INSTALL_LIBDIR=lib \
        -D CMAKE_BUILD_TYPE=Release \
        -D RANGE_V3_TESTS=OFF \
        -D RANGE_V3_EXAMPLES=OFF \
        -D RANGE_V3_PERF=OFF \
        -D RANGE_V3_DOCS=OFF \
        -D RANGE_V3_HEADER_CHECKS=OFF
}

package() {
    DESTDIR="$DESTDIR" cmake --install build
}
