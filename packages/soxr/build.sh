# Not in the book: the newest upstream release (0.1.3, the last one), built
# as its INSTALL file says, with CMake.
build() {
    mkdir build
    cd build
    # - CMAKE_POLICY_VERSION_MINIMUM: the release asks for CMake 3.1, which
    #   CMake 4 no longer accepts without it.
    # - The FFT for the SIMD engine is the bundled PFFFT; libavcodec's
    #   (WITH_AVFFT) is gone from current FFmpeg.
    # - libsoxr-lsr, the libsamplerate-compatible interface, is built as
    #   upstream does by default.
    # - No OpenMP, as Audacity builds it; no developer tracing, tests or
    #   examples.
    cmake -D CMAKE_BUILD_TYPE=Release \
        -D CMAKE_INSTALL_PREFIX=/usr \
        -D CMAKE_POLICY_VERSION_MINIMUM=3.5 \
        -D LIB_INSTALL_DIR=/usr/lib \
        -D BUILD_SHARED_LIBS=ON \
        -D BUILD_TESTS=OFF \
        -D BUILD_EXAMPLES=OFF \
        -D WITH_OPENMP=OFF \
        -D WITH_LSR_BINDINGS=ON \
        -D WITH_PFFFT=ON \
        -D WITH_AVFFT=OFF \
        -D WITH_DEV_TRACE=OFF \
        -G Ninja ..
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
