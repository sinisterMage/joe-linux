# Not in the book: the newest SDL 2 release of SDL_ttf, built with its
# CMake build against the system FreeType and HarfBuzz (text shaping for
# complex scripts, off by upstream's default) instead of the copies in
# external/. The sample programs are not built.
build() {
    cmake -B build -G Ninja \
        -D CMAKE_INSTALL_PREFIX=/usr \
        -D CMAKE_INSTALL_LIBDIR=lib \
        -D CMAKE_BUILD_TYPE=Release \
        -D CMAKE_SKIP_INSTALL_RPATH=ON \
        -D BUILD_SHARED_LIBS=ON \
        -D SDL2TTF_VENDORED=OFF \
        -D SDL2TTF_HARFBUZZ=ON \
        -D SDL2TTF_SAMPLES=OFF
    ninja -C build
}

package() {
    DESTDIR="$DESTDIR" ninja -C build install
}
