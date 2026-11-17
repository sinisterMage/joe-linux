# Not in the book: the newest upstream release, built with CMake as its
# README.md says.
prepare() {
    # Keep RTTI, as other distributions do: upstream builds with -fno-rtti,
    # and programs built with RTTI that implement leveldb's interfaces
    # (Comparator, Env, Logger, ...) then fail to link for want of their
    # type information.
    sed -i '/CMAKE_CXX_FLAGS} -fno-rtti")/d' CMakeLists.txt
    if grep -q -- '-fno-rtti' CMakeLists.txt; then
        echo 'leveldb: -fno-rtti is still in CMakeLists.txt' >&2
        return 1
    fi
}

build() {
    # The libraries leveldb looks for are stated rather than detected:
    # snappy on; crc32c and tcmalloc have no recipe (leveldb then uses its
    # own CRC32C code and the C library's malloc). The tests and benchmarks
    # would build the googletest and benchmark copies, which the archive
    # does not contain anyway.
    cmake -B build -G Ninja \
        -D CMAKE_INSTALL_PREFIX=/usr \
        -D CMAKE_INSTALL_LIBDIR=lib \
        -D CMAKE_BUILD_TYPE=Release \
        -D BUILD_SHARED_LIBS=ON \
        -D LEVELDB_BUILD_TESTS=OFF \
        -D LEVELDB_BUILD_BENCHMARKS=OFF \
        -D HAVE_SNAPPY=ON \
        -D HAVE_CRC32C=OFF \
        -D HAVE_TCMALLOC=OFF
    ninja -C build
}

package() {
    DESTDIR="$DESTDIR" ninja -C build install
}
