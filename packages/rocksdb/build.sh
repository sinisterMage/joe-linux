# Not in the book: the newest upstream release, built with CMake as its
# INSTALL.md describes.
prepare() {
    # Only the shared library: the static one is always built and installed
    # otherwise (from the same sources, doubling the build). Its target is
    # left out of the default build and of the installed CMake export set.
    sed -i 's/^add_library(${ROCKSDB_STATIC_LIB} STATIC /&EXCLUDE_FROM_ALL /' CMakeLists.txt
    sed -i '/^  install($/{N;/\n    TARGETS \${ROCKSDB_STATIC_LIB}$/{:a;N;/\n  )$/!ba;d}}' CMakeLists.txt
    grep -q 'STATIC EXCLUDE_FROM_ALL' CMakeLists.txt
    if grep -q 'TARGETS ${ROCKSDB_STATIC_LIB}' CMakeLists.txt; then
        echo 'rocksdb: the static library is still installed' >&2
        return 1
    fi
}

build() {
    # - PORTABLE: baseline x86_64 instead of -march=native (CRC32C then
    #   uses its portable code rather than SSE4.2 instructions).
    # - Compression: snappy, LZ4, zlib, Zstandard and bzip2.
    # - USE_RTTI: the type information that programs built with RTTI need
    #   to implement RocksDB's interfaces (upstream drops it in Release).
    # - Off: jemalloc (linking it would replace malloc in every program that
    #   loads the library), liburing, gflags, NUMA and folly (no recipes),
    #   Java, the tests, benchmarks and tools (CMake installs none of the
    #   tools), and -Werror.
    cmake -B build -G Ninja \
        -D CMAKE_INSTALL_PREFIX=/usr \
        -D CMAKE_INSTALL_LIBDIR=lib \
        -D CMAKE_BUILD_TYPE=Release \
        -D PORTABLE=ON \
        -D ROCKSDB_BUILD_SHARED=ON \
        -D USE_RTTI=ON \
        -D FAIL_ON_WARNINGS=OFF \
        -D WITH_SNAPPY=ON \
        -D WITH_LZ4=ON \
        -D WITH_ZLIB=ON \
        -D WITH_ZSTD=ON \
        -D WITH_BZ2=ON \
        -D WITH_JEMALLOC=OFF \
        -D WITH_LIBURING=OFF \
        -D WITH_GFLAGS=OFF \
        -D WITH_NUMA=OFF \
        -D USE_FOLLY=OFF \
        -D WITH_JNI=OFF \
        -D WITH_TESTS=OFF \
        -D WITH_BENCHMARK_TOOLS=OFF \
        -D WITH_CORE_TOOLS=OFF \
        -D WITH_TOOLS=OFF \
        -D WITH_TRACE_TOOLS=OFF \
        -D WITH_EXAMPLES=OFF \
        -D WITH_BENCHMARK=OFF
    ninja -C build
}

package() {
    DESTDIR="$DESTDIR" ninja -C build install
}
