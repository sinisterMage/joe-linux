# Not in the book: the newest upstream release, built with CMake as its
# documentation describes.
build() {
    # The shared libflatbuffers instead of the static one, and flatc; no
    # tests, samples, benchmarks or flathash.
    cmake -B build -G Ninja \
        -D CMAKE_INSTALL_PREFIX=/usr \
        -D CMAKE_INSTALL_LIBDIR=lib \
        -D CMAKE_BUILD_TYPE=Release \
        -D FLATBUFFERS_BUILD_SHAREDLIB=ON \
        -D FLATBUFFERS_BUILD_FLATLIB=OFF \
        -D FLATBUFFERS_BUILD_FLATC=ON \
        -D FLATBUFFERS_BUILD_TESTS=OFF \
        -D FLATBUFFERS_BUILD_BENCHMARKS=OFF \
        -D FLATBUFFERS_BUILD_FLATHASH=OFF
    ninja -C build
}

package() {
    DESTDIR="$DESTDIR" ninja -C build install
}
