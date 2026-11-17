# Not in the book: the newest upstream release, built as its README says,
# with the command-line tool fpcalc (BUILD_TOOLS). The FFT is FFmpeg's
# (avtx), named so that FFTW, which exists too, is not picked instead; the
# test suite (googletest) is not built.
build() {
    cmake -B build -G Ninja \
        -D CMAKE_INSTALL_PREFIX=/usr \
        -D CMAKE_INSTALL_LIBDIR=lib \
        -D CMAKE_BUILD_TYPE=Release \
        -D BUILD_SHARED_LIBS=ON \
        -D BUILD_TOOLS=ON \
        -D BUILD_TESTS=OFF \
        -D FFT_LIB=avtx \
        -D AUDIO_PROCESSOR_LIB=swresample
    ninja -C build
}

package() {
    DESTDIR="$DESTDIR" ninja -C build install
}
