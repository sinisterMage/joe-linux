# Not in the book: the newest upstream release of c-blosc (the 1.x library;
# Blosc2 is a separate project), built as its README.md says.
build() {
    # PREFER_EXTERNAL_*: link the system LZ4, zlib and Zstandard rather than
    # the bundled copies. Snappy, which upstream leaves off by default as
    # deprecated, is on so that data other Blosc builds wrote with it can be
    # read. SSE2 and AVX2 code is chosen at run time from the CPU's
    # features, so the library stays portable.
    cmake -B build -G Ninja \
        -D CMAKE_INSTALL_PREFIX=/usr \
        -D CMAKE_INSTALL_LIBDIR=lib \
        -D CMAKE_BUILD_TYPE=Release \
        -D BUILD_SHARED=ON \
        -D BUILD_STATIC=OFF \
        -D BUILD_TESTS=OFF \
        -D BUILD_FUZZERS=OFF \
        -D BUILD_BENCHMARKS=OFF \
        -D DEACTIVATE_LZ4=OFF \
        -D DEACTIVATE_SNAPPY=OFF \
        -D DEACTIVATE_ZLIB=OFF \
        -D DEACTIVATE_ZSTD=OFF \
        -D PREFER_EXTERNAL_LZ4=ON \
        -D PREFER_EXTERNAL_ZLIB=ON \
        -D PREFER_EXTERNAL_ZSTD=ON
    ninja -C build
}

package() {
    DESTDIR="$DESTDIR" ninja -C build install
}
