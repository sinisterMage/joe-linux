# Not in the book: the newest upstream release, built with CMake as its
# INSTALL file describes: the full library (not libxmp-lite), shared only,
# with its built-in archive depackers and ProWizard loaders. SDL2_mixer
# plays MOD music through it.
build() {
    cmake -B build -G Ninja \
        -D CMAKE_INSTALL_PREFIX=/usr \
        -D CMAKE_INSTALL_LIBDIR=lib \
        -D CMAKE_BUILD_TYPE=Release \
        -D BUILD_SHARED=ON \
        -D BUILD_STATIC=OFF \
        -D BUILD_LITE=OFF \
        -D WITH_UNIT_TESTS=OFF
    ninja -C build
}

package() {
    DESTDIR="$DESTDIR" ninja -C build install
}
