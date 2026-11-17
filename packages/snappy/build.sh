# Not in the book: the newest upstream release, built with CMake as its
# README.md says.
prepare() {
    # Keep RTTI, as other distributions do: upstream builds with -fno-rtti,
    # which leaves out the type information of snappy::Source and
    # snappy::Sink, and programs built with RTTI that derive from them then
    # fail to link.
    sed -i '/CMAKE_CXX_FLAGS} -fno-rtti")/d' CMakeLists.txt
    if grep -q -- '-fno-rtti' CMakeLists.txt; then
        echo 'snappy: -fno-rtti is still in CMakeLists.txt' >&2
        return 1
    fi
}

build() {
    # The bundled googletest and benchmark are only used by the tests and
    # benchmarks, which are off. No SNAPPY_REQUIRE_AVX*, so the library
    # runs on any x86_64 processor.
    cmake -B build -G Ninja \
        -D CMAKE_INSTALL_PREFIX=/usr \
        -D CMAKE_INSTALL_LIBDIR=lib \
        -D CMAKE_BUILD_TYPE=Release \
        -D BUILD_SHARED_LIBS=ON \
        -D SNAPPY_BUILD_TESTS=OFF \
        -D SNAPPY_BUILD_BENCHMARKS=OFF \
        -D SNAPPY_FUZZING_BUILD=OFF \
        -D SNAPPY_REQUIRE_AVX=OFF \
        -D SNAPPY_REQUIRE_AVX2=OFF
    ninja -C build
}

package() {
    DESTDIR="$DESTDIR" ninja -C build install
}
