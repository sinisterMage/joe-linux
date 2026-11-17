# Following the book's sdl2 page, which is sdl2-compat 2.32.74. The
# package keeps the name sdl2 (what programs and the roadmap ask for).
# pkg-config finds it as "sdl2" through the Provides line of
# sdl2-compat.pc (pkgconf resolves names that way).
build() {
    mkdir build
    cd build
    cmake -D CMAKE_INSTALL_PREFIX=/usr \
        -D CMAKE_INSTALL_LIBDIR=lib \
        -D CMAKE_BUILD_TYPE=Release \
        -D CMAKE_SKIP_INSTALL_RPATH=ON \
        -D SDL2COMPAT_STATIC=OFF \
        -D SDL2COMPAT_TESTS=OFF \
        -W no-author -G Ninja ..
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
    rm -vf "$DESTDIR/usr/lib/libSDL2_test.a"
}
